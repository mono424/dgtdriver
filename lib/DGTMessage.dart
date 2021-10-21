class DGTMessage {
  int _code;
  int _length;
  List<int> _message;

  DGTMessage.parse(List<int> message) {
    if (message.length < 3) throw DGTMessageToShortException(message);

    int code = message[0], sizeMsb = message[1], sizeLsb = message[2];
    if ((code & 0x80) == 0) throw DGTInvalidMessageException(message);
    if ((sizeMsb & 0x80) != 0) throw DGTInvalidMsbException(message);
    if ((sizeLsb & 0x80) != 0) throw DGTInvalidLsbException(message);

    int messageLen = (sizeMsb << 7) | sizeLsb;
    if (messageLen > message.length) throw DGTMessageToShortException(message);

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

abstract class DGTMessageException implements Exception {
  final List<int> buffer;
  DGTMessageException(this.buffer);
}

class DGTMessageToShortException extends DGTMessageException {
  DGTMessageToShortException(List<int> buffer) : super(buffer);
}

class DGTInvalidMessageException extends DGTMessageException {
  DGTInvalidMessageException(List<int> buffer) : super(buffer);
}

class DGTInvalidMsbException extends DGTMessageException {
  DGTInvalidMsbException(List<int> buffer) : super(buffer);
}

class DGTInvalidLsbException extends DGTMessageException {
  DGTInvalidLsbException(List<int> buffer) : super(buffer);
}
