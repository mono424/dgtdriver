import 'dart:async';
import 'dart:typed_data';

import 'package:dgtdriver/DGTCommunicationClient.dart';
import 'package:dgtdriver/DGTMessage.dart';
import 'package:dgtdriver/models/BatteryStatus.dart';
import 'package:dgtdriver/models/ClockMessage.dart';
import 'package:dgtdriver/models/FieldUpdate.dart';
import 'package:dgtdriver/models/LEDPattern.dart';
import 'package:dgtdriver/models/Piece.dart';
import 'package:dgtdriver/protocol/ClockAnswer.dart';
import 'package:dgtdriver/protocol/DGTProtocol.dart';
import 'package:dgtdriver/protocol/commands/BatteryUpdate.dart';
import 'package:dgtdriver/protocol/commands/FieldUpdate.dart';
import 'package:dgtdriver/protocol/commands/GetBoard.dart';
import 'package:dgtdriver/protocol/commands/GetClockInfo.dart';
import 'package:dgtdriver/protocol/commands/GetClockVersion.dart';
import 'package:dgtdriver/protocol/commands/GetSerialNumber.dart';
import 'package:dgtdriver/protocol/commands/GetVersion.dart';
import 'package:dgtdriver/protocol/commands/MagicPegasusHandshakeCommand.dart';
import 'package:dgtdriver/protocol/commands/RequestDeviceInfoCommand.dart';
import 'package:dgtdriver/protocol/commands/SendClockAscii.dart';
import 'package:dgtdriver/protocol/commands/SendClockBeep.dart';
import 'package:dgtdriver/protocol/commands/SendClockSet.dart';
import 'package:dgtdriver/protocol/commands/SendReset.dart';
import 'package:dgtdriver/protocol/commands/SendUpdate.dart';
import 'package:dgtdriver/protocol/commands/SendUpdateBattery.dart';
import 'package:dgtdriver/protocol/commands/SendUpdateBoard.dart';
import 'package:dgtdriver/protocol/commands/SendUpdateNice.dart';
import 'package:dgtdriver/protocol/commands/SetLEDPattern.dart';

class DGTBoard {
  
  DGTCommunicationClient _client;

  StreamController _inputStreamController;
  Stream<DGTMessage> _inputStream;
  List<int> _buffer;

  String _serialNumber;
  String _version;
  Map<String, Piece> _boardState;
  Map<String, Piece> _lastSeen;

  String _pegasusDeviceInfo;

  DGTBoard();

  Future<void> init(DGTCommunicationClient client, { Duration initialDelay = const Duration(milliseconds: 300) }) async {
    _client = client;

    _client.receiveStream.listen(_handleInputStream);
    _inputStreamController = new StreamController<DGTMessage>();
    _inputStream = _inputStreamController.stream.asBroadcastStream();

    _inputStream.handleError((e) {
      print("Error: " + e.toString());
    });

    await Future.delayed(initialDelay);
    await reset();
  }

  void _handleClockUpdate(ClockMessage update) {}

  void _handleBoardUpdate(DetailedFieldUpdate update) {
    if (update.action == FieldUpdateAction.setdown) {
      _boardState[update.field] = update.piece;
      _lastSeen[update.field] = update.piece;
    } else {
      _boardState[update.field] = null;
    }
  }

  void _handleInputStream(Uint8List rawChunk) {
    List<int> chunk = rawChunk.toList();
    print("received chunk ...");
    if (_buffer == null)
      _buffer = chunk.toList();
    else
      _buffer.addAll(chunk);

    try {
      DGTMessage message = DGTMessage.parse(_buffer);
      _inputStreamController.add(message);
      _buffer.removeRange(0, message.getLength());
      print("Received valid message: " + message.getCode().toString());
      print("-> " + message.getMessage().toString());
    } on DGTInvalidMessageException catch (e) {
      _buffer = skipBadBytes(1, _buffer);
      _inputStreamController.addError(e);
    } on DGTInvalidMsbException catch (e) {
      _buffer = skipBadBytes(2, _buffer);
      _inputStreamController.addError(e);
    } on DGTInvalidLsbException catch (e) {
      _buffer = skipBadBytes(3, _buffer);
      _inputStreamController.addError(e);
    } on DGTMessageToShortException catch (_) {
      // _inputStreamController.addError(e);
    } catch (err) {
      // print("Unknown parse-error: " + err.toString());
      _inputStreamController.addError(err);
    }
  }

  Stream<DGTMessage> getInputStream() {
    return _inputStream;
  }

  List<int> skipBadBytes(int start, List<int> buffer) {
    int startOfGoodBytes = start;
    for (; startOfGoodBytes < buffer.length; startOfGoodBytes++) {
      if ((buffer[startOfGoodBytes] & 0x80) != 0) break;
    }
    if (startOfGoodBytes == buffer.length) return [];
    return buffer.sublist(startOfGoodBytes, buffer.length - startOfGoodBytes);
  }

  Future<void> reset() async {
    await SendResetCommand().send(_client);
    _serialNumber = await GetSerialNumberCommand().request(_client, _inputStream);
    _version = await GetVersionCommand().request(_client, _inputStream);

    if (isPegasusBoard) {
      await MagicPegasusHandshakeCommand().send(_client);
      _pegasusDeviceInfo = await RequestDeviceInfoCommand().request(_client, _inputStream);
      await SendResetCommand().send(_client);
    }

    _setBoardState(await GetBoardCommand().request(_client, _inputStream));
    _lastSeen = getBoardState();
    getBoardDetailedUpdateStream().listen(_handleBoardUpdate);
    getClockUpdateStream().listen(_handleClockUpdate);
  }

  void _setBoardState(Map<String, Piece> rawBoardState) {
    if (isPegasusBoard) {
      _boardState = rawBoardState.map<String, Piece>((k,v) => v != null ? MapEntry(k, PegasusPiece()) : MapEntry(k, null));
      return;
    }
    _boardState = rawBoardState;
  }

  bool get isPegasusBoard {
    return _version == "1.0";
  }

  String get getPegasusDeviceInfo {
    return isPegasusBoard ? _pegasusDeviceInfo : null;
  }

  String getSerialNumber() {
    return _serialNumber;
  }

  String getVersion() {
    return _version;
  }

  Map<String, Piece> getBoardState() {
    return _boardState.map((k,v) => MapEntry(k, v == null ? null : v.clone()));
  }

  Future<ClockInfoMessage> getClockInfo() {
    return GetClockInfoCommand().request(_client, _inputStream);
  }

  Future<BatteryStatus> getBatteryUpdate() {
    return SendUpdateBatteryCommand().request(_client, _inputStream);
  }

  /*
   * DGT Clock
   */

  Future<ClockVersionMessage> getClockVersion() async {
    return GetClockVersionCommand().request(_client, _inputStream);
  }

  Future<ClockMessage> clockBeep(Duration duration) {
    return SendClockBeepCommand(duration).request(_client, _inputStream);
  }
  
  Future<ClockMessage> clockSet(Duration timeLeft, Duration timeRight, bool leftIsRunning, bool rightIsRunning, bool pause, bool toggleOnLever) {
    return SendClockSetCommand(timeLeft, timeRight, leftIsRunning, rightIsRunning, pause, toggleOnLever).request(_client, _inputStream);
  }
  
  Future<ClockMessage> clockText(String text, { Duration beep = Duration.zero}) {
    return SendClockAsciiCommand(text, beep).request(_client, _inputStream);
  }

  /*
   * Board Modes - Sets the board to the desired mode
   */

  /// Board will notify on battery percentage change
  Future<void> setBoardToUpdateBatteryMode() async {
    if (!isPegasusBoard) return;
    await SendUpdateBatteryCommand().send(_client);
  }

  /// Board will notify on board events
  Future<void> setBoardToUpdateBoardMode() async {
    await SendUpdateBoardCommand().send(_client);
  }

  /// Board will notify on board and clock events
  Future<void> setBoardToUpdateMode() async {
    if (isPegasusBoard) return;
    await SendUpdateCommand().send(_client);
  }

  /// Board will notify on board and clock events
  Future<void> setBoardToUpdateNiceMode() async {
    if (isPegasusBoard) return;
    await SendUpdateNiceCommand().send(_client);
  }

  Stream<BatteryStatus> getBatteryUpdateStream() {
    return getInputStream()
        .where(
            (DGTMessage msg) => msg.getCode() == BatteryUpdateAnswer().code)
        .map((DGTMessage msg) => BatteryUpdateAnswer().process(msg.getMessage()));
  }

  Stream<ClockMessage> getClockUpdateStream() {
    return getInputStream()
        .where(
            (DGTMessage msg) => msg.getCode() == ClockAnswer().code)
        .map((DGTMessage msg) => ClockAnswer().process(msg.getMessage()));
  }

  Stream<FieldUpdate> getBoardUpdateStream() {
    return getInputStream()
        .where(
            (DGTMessage msg) => msg.getCode() == FieldUpdateAnswer().code)
        .map((DGTMessage msg) => FieldUpdateAnswer().process(msg.getMessage()))
        .map((FieldUpdate update) => 
          isPegasusBoard && update.piece != null 
          ? FieldUpdate(field: update.field, piece: PegasusPiece())
          : update
        );
  }

  Stream<DetailedFieldUpdate> getBoardDetailedUpdateStream() {
    return getBoardUpdateStream().map((FieldUpdate f) {
      if (f.piece == null) {
        return DetailedFieldUpdate(
            piece: _lastSeen[f.field],
            field: f.field,
            action: FieldUpdateAction.pickup);
      }
      return DetailedFieldUpdate(
          piece: f.piece, field: f.field, action: FieldUpdateAction.setdown);
    }).asBroadcastStream();
  }

  Future<void> setLEDPattern(LEDPattern pattern) async {
    if (!isPegasusBoard) return;
    await SetLEDPatternCommand(pattern).send(_client);
  }

  LEDPatternField ledPatternFieldFromAlgebra(String field) {
    return LEDPatternField(DGTProtocol.SQUARES.indexOf(field.toLowerCase()));
  }
}
