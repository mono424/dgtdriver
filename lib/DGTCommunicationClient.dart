import 'dart:async';

import 'dart:typed_data';

class DGTCommunicationClient {
  final Future<void> Function(Uint8List) send;
  final StreamController<Uint8List> _inputStreamController = StreamController<Uint8List>();

  Stream<Uint8List> get receiveStream {
    return _inputStreamController.stream.asBroadcastStream();
  }

  DGTCommunicationClient(this.send);

  handleReceive(Uint8List message) {
    _inputStreamController.add(message);
  }
}