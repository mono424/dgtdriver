import 'dart:typed_data';

import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/Command.dart';

class GetVersionCommand extends Command<String> {
  final int code = 0x4d;
  final Answer<String> answer = GetVersionAnswer();
}

class GetVersionAnswer extends Answer<String> {
  final int code = 0x13;

  String process(List<int> msg) {
    return msg[0].toString() + '.' + msg[1].toString();
  }
}