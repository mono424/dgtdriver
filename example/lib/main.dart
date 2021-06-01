import 'package:dgtdriver/DGTCommunicationClient.dart';
import 'package:dgtdriver/models/FieldUpdate.dart';
import 'package:dgtdriver/models/ClockMessage.dart';
import 'package:dgtdriver/protocol/ClockAnswerType.dart';
import 'package:dgtdriver/protocol/ClockButton.dart';
import 'package:flutter/material.dart';
import 'package:dgtdriver/DGTBoard.dart';
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

  void connect() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    List<UsbDevice> dgtDevices = devices.where((d) => d.vid == 1115).toList();
    UsbPort usbDevice = await dgtDevices[0].create();

    DGTCommunicationClient client = DGTCommunicationClient((List<int> message) async {
      usbDevice.write(message);
    });
    usbDevice.inputStream.listen(client.handleReceive);
    

    if (dgtDevices.length > 0) {
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

      // set board to update mode
      nBoard.setBoardToUpdateMode();
    }
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
          Center(child: TextButton(
            child: Text(connectedBoard == null ? "Try to connect to board" : "Connected"),
            onPressed: connectedBoard == null ? connect : null,
          )),
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
          ...(connectedBoard != null ? [
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
