import 'dart:convert';

import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/Command.dart';

class RequestDeviceInfoCommand extends Command<String> {
  final int code = 0x47;
  final Answer<String> answer = RequestDeviceInfoAnswer();
}

class RequestDeviceInfoAnswer extends Answer<String> {
  final int code = 0x12;

  String process(List<int> msg) {
    String text = utf8.decode(msg);
    return text;
  }
}