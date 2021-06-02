import 'dart:async';
import 'dart:typed_data';

import 'package:dgtdriver/DGTCommunicationClient.dart';
import 'package:dgtdriver/DGTMessage.dart';
import 'package:dgtdriver/models/ClockMessage.dart';
import 'package:dgtdriver/models/FieldUpdate.dart';
import 'package:dgtdriver/models/Piece.dart';
import 'package:dgtdriver/protocol/ClockAnswer.dart';
import 'package:dgtdriver/protocol/DGTProtocol.dart';
import 'package:dgtdriver/protocol/commands/FieldUpdate.dart';
import 'package:dgtdriver/protocol/commands/GetBoard.dart';
import 'package:dgtdriver/protocol/commands/GetClockInfo.dart';
import 'package:dgtdriver/protocol/commands/GetClockVersion.dart';
import 'package:dgtdriver/protocol/commands/GetSerialNumber.dart';
import 'package:dgtdriver/protocol/commands/GetVersion.dart';
import 'package:dgtdriver/protocol/commands/SendClockAscii.dart';
import 'package:dgtdriver/protocol/commands/SendClockBeep.dart';
import 'package:dgtdriver/protocol/commands/SendClockSet.dart';
import 'package:dgtdriver/protocol/commands/SendReset.dart';
import 'package:dgtdriver/protocol/commands/SendUpdate.dart';
import 'package:dgtdriver/protocol/commands/SendUpdateBoard.dart';
import 'package:dgtdriver/protocol/commands/SendUpdateNice.dart';

class DGTBoard {
  
  DGTCommunicationClient _client;

  StreamController _inputStreamController;
  Stream<DGTMessage> _inputStream;
  List<int> _buffer;

  String _serialNumber;
  String _version;
  Map<String, Piece> _boardState;
  Map<String, Piece> _lastSeen;

  DGTBoard();

  Future<void> init(DGTCommunicationClient client, { Duration initialDelay = const Duration(milliseconds: 300) }) async {
    _client = client;

    _client.receiveStream.listen(_handleInputStream);
    _inputStreamController = new StreamController<DGTMessage>();
    _inputStream = _inputStreamController.stream.asBroadcastStream();

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
    print(chunk);
    if (_buffer == null)
      _buffer = chunk.toList();
    else
      _buffer.addAll(chunk);

    try {
      DGTMessage message = DGTMessage.parse(_buffer);
      _inputStreamController.add(message);
      _buffer.removeRange(0, message.getLength());
    } on DGTInvalidMessageException {
      _buffer = skipBadBytes(1, _buffer);
    } on DGTInvalidMsbException {
      _buffer = skipBadBytes(2, _buffer);
    } on DGTInvalidLsbException {
      _buffer = skipBadBytes(3, _buffer);
    } catch (err) {
      print("Unknown parse-error: " + err.toString());
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
    _boardState = await GetBoardCommand().request(_client, _inputStream);
    _lastSeen = getBoardState();
    getBoardDetailedUpdateStream().listen(_handleBoardUpdate);
    getClockUpdateStream().listen(_handleClockUpdate);
  }

  String getSerialNumber() {
    return _serialNumber;
  }

  String getVersion() {
    return _version;
  }

  Map<String, Piece> getBoardState() {
    Map<String, Piece> clone = Map<String, Piece>();
    clone.addAll(_boardState);
    clone.values.map((e) => e.clone());
    return clone;
  }

  Future<ClockInfoMessage> getClockInfo() {
    return GetClockInfoCommand().request(_client, _inputStream);
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

  /// Reverse Board orientation
  void setBoardOrientation(bool reversed) async {
    bool prevOrientation = DGTProtocol.reverseBoardOrientation;
    if (prevOrientation != reversed) {
      List<String> oldSquares = DGTProtocol.squares;
      Map<String, Piece> oldBoardState = getBoardState();
      Map<String, Piece> newBoardState = {};

      DGTProtocol.reverseBoardOrientation = reversed;
      List<String> newSquares = DGTProtocol.squares;

      for (var i = 0; i < newSquares.length; i++) {
        newBoardState[newSquares[i]] = oldBoardState[oldSquares[i]];
      }

      _boardState = newBoardState;
    }
  }

  /// Board will notify on board events
  Future<void> setBoardToUpdateBoardMode() async {
    await SendUpdateBoardCommand().send(_client);
  }

  /// Board will notify on board and clock events
  Future<void> setBoardToUpdateMode() async {
    await SendUpdateCommand().send(_client);
  }

  /// Board will notify on board and clock events
  Future<void> setBoardToUpdateNiceMode() async {
    await SendUpdateNiceCommand().send(_client);
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
        .map((DGTMessage msg) => FieldUpdateAnswer().process(msg.getMessage()));
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
}
