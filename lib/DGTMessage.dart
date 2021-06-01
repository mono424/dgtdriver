class DGTMessage {
  int _code;
  int _length;
  List<int> _message;

  DGTMessage.parse(List<int> message) {
    if (message.length < 3) throw DGTMessageToShortException();

    int code = message[0], sizeMsb = message[1], sizeLsb = message[2];
    if ((code & 0x80) == 0) throw DGTInvalidMessageException();
    if ((sizeMsb & 0x80) != 0) throw DGTInvalidMsbException();
    if ((sizeLsb & 0x80) != 0) throw DGTInvalidLsbException();

    int messageLen = (sizeMsb << 7) | sizeLsb;
    if (messageLen > message.length) throw DGTMessageToShortException();

    _code = code & 0x7f;
    _length = messageLen;
    _message = messageLen > 3 ? message.sublist(3) : null;
  }

  int getCode() {
    return _code;
  }

  int getLength() {
    return _length;
  }

  List<int> getMessage() {
    return _message;
  }
}

class DGTMessageToShortException implements Exception {}

class DGTInvalidMessageException implements Exception {}

class DGTInvalidMsbException implements Exception {}

class DGTInvalidLsbException implements Exception {}
