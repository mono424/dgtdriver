import 'dart:typed_data';

import 'package:dgtdriver/DGTCommunicationClient.dart';
import 'package:dgtdriver/models/BatteryStatus.dart';
import 'package:dgtdriver/models/LEDPattern.dart';
import 'package:dgtdriver/models/FieldUpdate.dart';
import 'package:dgtdriver/models/ClockMessage.dart';
import 'package:dgtdriver/protocol/ClockAnswerType.dart';
import 'package:dgtdriver/protocol/ClockButton.dart';
import 'package:flutter/material.dart';
import 'package:dgtdriver/DGTBoard.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DGTBoard connectedBoard;
  ClockInfoMessage lastClockInfo;
  List<ClockMessage> lastClockAcks = [];
  List<ClockButton> lastClockButtons = [];

  TextEditingController _clockAsciiTextController = new TextEditingController();

  String _characteristicReadId = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  String _characteristicWriteId = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  Duration scanDuration = Duration(seconds: 4);
  List<ScanResult> devices = [];
  bool scanning = false;
  
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice _port;
  BluetoothCharacteristic _characteristicRead;
  BluetoothCharacteristic _characteristicWrite;


  void connectBle() async {
    if (_port == null) {
      // Start scanning
      flutterBlue.startScan(timeout: scanDuration);

      // Listen to scan results
      _port = (
        await flutterBlue.scanResults.firstWhere((r) => r.where((r) => r.device.name.contains("DGT")).length > 0)
      ).where((r) => r.device.name.contains("DGT")).first.device;

      if (_port == null) return;
    }
    try {
      await _port.connect();
    } catch (_) {}
    
    List<BluetoothService> services = await _port.discoverServices();

    for (BluetoothService s in services) {
      for (BluetoothCharacteristic c in s.characteristics) {
        if (c.uuid.toString() == _characteristicReadId) _characteristicRead = c;
        if (c.uuid.toString() == _characteristicWriteId) _characteristicWrite = c;
        if (c.properties.write) print("Write avaiable on: " + c.uuid.toString());
        if (c.properties.read && c.properties.notify) print("Read/Noitify avaiable on: " + c.uuid.toString());
      }
    }

    await _characteristicRead.setNotifyValue(true);

    DGTCommunicationClient client = DGTCommunicationClient(
      (list) {
        print(list.toList());
        return _characteristicWrite.write(list.toList());
      }
    );
    _characteristicRead.value.listen((list) => client.handleReceive(Uint8List.fromList(list)));
    
    connect(client);
  }

  void connectUsb() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    List<UsbDevice> dgtDevices = devices.where((d) => d.vid == 1115).toList();
    if (dgtDevices.length == 0) return;

    UsbPort usbDevice = await dgtDevices[0].create();
    await usbDevice.open();

    DGTCommunicationClient client = DGTCommunicationClient(usbDevice.write);
    usbDevice.inputStream.listen(client.handleReceive);
    
    connect(client);
  }

  void connect(DGTCommunicationClient client) async {
    // connect to board and initialize
    DGTBoard nBoard = new DGTBoard();
    await nBoard.init(client);
    print("DGTBoard connected - SerialNumber: " +
        nBoard.getSerialNumber() +
        " Version: " +
        nBoard.getVersion());

    // set connected board
    setState(() {
      connectedBoard = nBoard;
    });

    // If not pegasus -> Board & Clock Updates.
    // Otherwise only Board Updates
    if (nBoard.isPegasusBoard) {
      await nBoard.setBoardToUpdateBoardMode();
    } else {
      await nBoard.setBoardToUpdateMode();
    }

    // set board to update charge mode
    await nBoard.setBoardToUpdateBatteryMode();
  }

  void _showClockAsciiDialog(context) async {
    String text = await showDialog(context: context, builder: (context) {
      return AlertDialog(
        contentPadding: EdgeInsets.all(16.0),
        content: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _clockAsciiTextController,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: 'Text', hintText: 'Write something'),
                ),
            )
          ],
        ),
        actions: <Widget>[
          TextButton(
              child: Text('Send'),
              onPressed: () {
                Navigator.pop(context, _clockAsciiTextController.text);
              })
        ],
      );
    });

    connectedBoard.clockText(text, beep: Duration(milliseconds: 200));
  }

  void _sendClockBeep() {
    connectedBoard.clockBeep(Duration(milliseconds: 200));
  }

  void _testLeds() {
    connectedBoard.setLEDPattern(LEDPattern(
      speed: LEDPatternSpeed.speed7,
      brightness: LEDPatternBrightness.high,
      repeat: LEDPatternRepeat.once,
      fields: [
        // LEDPatternField.fromAlgebra("e7"),
        LEDPatternField.fromAlgebra("e6"),
        // LEDPatternField.fromAlgebra("c3"),
        // LEDPatternField.fromAlgebra("d4"),
        // LEDPatternField.fromAlgebra("e5"),
        // LEDPatternField.fromAlgebra("f6"),
        // LEDPatternField.fromAlgebra("g7"),
        // LEDPatternField.fromAlgebra("h8"),
      ]
    ));
  }

  void _testSetClock1() {
    connectedBoard.clockSet(
      Duration(minutes: 4, seconds: 20),
      Duration(minutes: 20, seconds: 4),
      false,
      true,
      false,
      true
    );
  }

  void _disconnectBle() {
    _port.disconnect();
    setState(() {
      _port = null;
      connectedBoard = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("dgtdriver example"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...(
            connectedBoard != null ? [
              Text("Connected")
            ] : [
              TextButton(
                child: Text("Try to connect to USB"),
                onPressed: connectUsb
              ),
              TextButton(
                child: Text("Try to connect to BLE"),
                onPressed: connectBle
              )
            ]
          ),
          Center( child: StreamBuilder(
            stream: connectedBoard?.getBoardDetailedUpdateStream(),
            builder: (context, AsyncSnapshot<DetailedFieldUpdate> snapshot) {
              if (!snapshot.hasData) return Text("-");

              DetailedFieldUpdate fieldUpdate = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Last Update: "),
                  Text("Square: " + fieldUpdate.field),
                  Text("Action: " + fieldUpdate.action.toString()),
                  Text("Piece: " + fieldUpdate.piece.role + " (" + fieldUpdate.piece.color + ")"),
                  Text("Notation: " + fieldUpdate.getNotation()),
                ],
              );
            }
          )),
          ...(connectedBoard != null && connectedBoard.isPegasusBoard ? [
            SizedBox(height: 34),
            Text("Pegasus Board"),
            TextButton(child: Text("Disconnect"), onPressed: () => _disconnectBle()),
            StreamBuilder(
              stream: connectedBoard?.getBatteryUpdateStream(),
              builder: (context, AsyncSnapshot<BatteryStatus> snapshot) {
                if (!snapshot.hasData) return Text("-");

                BatteryStatus status = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Battery Percentage: " + status.charge.toString()),
                    Text("Charging: " + (status.isCharging ? "Yes" : "No")),
                  ],
                );
              }
            ),
            TextButton(child: Text("Test LED's"), onPressed: () => _testLeds()),
          ] : []),
          ...(connectedBoard != null && !connectedBoard.isPegasusBoard ? [
            SizedBox(height: 34),
            Text("Clock Tests"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(child: Text("Send Beep"), onPressed: () => _sendClockBeep()),
                TextButton(child: Text("Test Set 1"), onPressed: () => _testSetClock1()),
                TextButton(child: Text("Send Text"), onPressed: () => _showClockAsciiDialog(context))
              ],
            ),
          ] : []),
          Center(child: StreamBuilder(
            stream: connectedBoard?.getClockUpdateStream(),
            builder: (context, AsyncSnapshot<ClockMessage> snapshot) {
              if (!snapshot.hasData) return Text("-");

              ClockMessage message = snapshot.data;
              if (message.type == ClockAnswerType.info) {
                lastClockInfo = message;
              } else {
                lastClockAcks.add(message);
                if (message is ClockButtonMessage) {
                  lastClockButtons.add(message.button);
                }
              }

              if (lastClockInfo == null) return Text("-");

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text("Clock Acks(last): " + (lastClockAcks.isNotEmpty ? lastClockAcks.last.type.toString() : "-")),
                    Text("Clock Connected: " + (lastClockInfo.clockFlags.clockConnected ? "Yes" : "No")),
                    Text("Clock Running: " + (lastClockInfo.clockFlags.clockRunning ? "Yes" : "No")),
                    Text("Clock lever: " + (lastClockInfo.clockFlags.rightHigh ? "Left" : "Right")),
                    Text("Clock Battery: " + (lastClockInfo.clockFlags.batteryLow ? "Low" : "Normal")),
                    Text("Clock LeftToMove: " + (lastClockInfo.clockFlags.leftToMove ? "Yes" : "No")),
                    Text("Clock RightToMove: " + (lastClockInfo.clockFlags.rightToMove ? "Yes" : "No")),
                    Text("Clock Left Player Time: " + lastClockInfo.left.time.toString()),
                    Text("Clock Left Player FinalFlag: " + (lastClockInfo.left.flags.finalFlag ? "Yes" : "No")),
                    Text("Clock Left Player FlagFlag: " + (lastClockInfo.left.flags.flag ? "Yes" : "No")),
                    Text("Clock Left Player TimePerMoveFlag: " + (lastClockInfo.left.flags.timePerMove ? "Yes" : "No")),
                    Text("Clock Right Player Time: " + lastClockInfo.right.time.toString()),
                    Text("Clock Right Player FinalFlag: " + (lastClockInfo.right.flags.finalFlag ? "Yes" : "No")),
                    Text("Clock Right Player FlagFlag: " + (lastClockInfo.right.flags.flag ? "Yes" : "No")),
                    Text("Clock Right Player TimePerMoveFlag: " + (lastClockInfo.right.flags.timePerMove ? "Yes" : "No")),
                    Text("Clock Buttons pressed(last): " + (lastClockButtons.isNotEmpty ? lastClockButtons.last.toString() : "-")),
                ],
              );
            }
          )),
        ],
      ),
    );
  }
}
