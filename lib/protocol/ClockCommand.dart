import 'dart:typed_data';

import 'package:dgtdriver/DGTMessage.dart';
import 'package:dgtdriver/models/ClockMessage.dart';
import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/ClockAnswer.dart';
import 'package:dgtdriver/protocol/ClockAnswerType.dart';
import 'package:dgtdriver/protocol/Command.dart';

abstract class ClockCommand extends Command<ClockMessage> {
  final int _clockMessageFlag = 0x2b;
  final int _startFlag = 0x03;
  final int _endFlag = 0x00;
  final Answer<ClockMessage> answer = ClockAnswer();
  
  ClockAnswerType answerType;

  Future<List<int>> data() async {
    return [];
  }

  Future<Uint8List> messageBuilder() async {
    int code = this.code;
    List<int> data = await this.data();
    int msgLen = data.length + 3;

    return Uint8List.fromList([
      _clockMessageFlag, 
      msgLen,
      _startFlag,
      code, /* the clock message id */
      ...data,
      _endFlag
    ]);
  }
  
  Future<ClockMessage> getReponse(Stream<DGTMessage> inputStream) async {
    if (answer == null) return null;
    DGTMessage message = await inputStream
        .firstWhere((DGTMessage msg) {
          if (msg.getCode() != answer.code) return false;
          ClockMessage cmsg = answer.process(msg.getMessage());
          return (cmsg?.ackFlags?.error ?? false) || cmsg.type == answerType;
        });
    return answer.process(message.getMessage());
  }
}