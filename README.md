# dgtdriver

The dgtdriver flutter package allows you to quickly get you dgt-board connected
to your Android application.

![preview](https://user-images.githubusercontent.com/17506411/114317384-1a680380-9b08-11eb-8484-b263743d43f6.gif)


## Getting Started with dgtdriver + usb_serial

Add dependencies to `pubspec.yaml`
```
dependencies:
	dgtdriver: ^0.0.1
	usb_serial: ^0.2.4
```

include the package
```
import 'package:dgtdriver/dgtdriver.dart';
import 'package:usb_serial/usb_serial.dart';
```

add compileOptions to `android\app\build.gradle`
```
android {
    ...
    compileOptions {
        sourceCompatibility 1.8
        targetCompatibility 1.8
    }
    ...
}
```
you can do optional more steps to allow usb related features,
for that please take a look at the package we depend on: 
[usb_serial](https://pub.dev/packages/usb_serial).


Connect to a connected board and listen to its events:
```dart
List<UsbDevice> devices = await UsbSerial.listDevices();
    List<UsbDevice> dgtDevices = devices.where((d) => d.vid == 1115).toList();
    UsbPort usbDevice = await dgtDevices[0].create();

    DGTCommunicationClient client = DGTCommunicationClient((List<int> message) async {
      usbDevice.write(Uint8List.fromList(message));
    });
    usbDevice.inputStream.listen((Uint8List message) => client.handleReceive(message.toList()));
    

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
```

## In action

To get a quick look, it is used in the follwoing project, which is not open source yet.

https://khad.im/p/white-pawn

## Updates soon

sorry for the lack of information, i will soon:

- update this readme
- add an example
- add some tests maybe
- make it crossplatform compatible (currently it depends on usb_serial package which makes it android exclusive. Linux, OSX and Windows should be possible aswell)
