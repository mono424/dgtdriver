import 'dart:async';

class DGTCommunicationClient {
  final Future<void> Function(List<int>) send;
  final StreamController<List<int>> _inputStreamController = StreamController<List<int>>();

  Stream<List<int>> get receiveStream {
    return _inputStreamController.stream.asBroadcastStream();
  }

  DGTCommunicationClient(this.send);

  handleReceive(List<int> message) {
    _inputStreamController.add(message);
  }
}