import 'dart:typed_data';

import 'package:dgtdriver/protocol/ClockAnswerType.dart';
import 'package:dgtdriver/protocol/ClockCommand.dart';

class SendClockSetCommand extends ClockCommand {
  final int code = 0x0a;
  final ClockAnswerType answerType = ClockAnswerType.setNRunAck;

  final Duration timeLeft;
  final Duration timeRight;
  final bool leftIsRunning;
  final bool rightIsRunning;
  final bool pause;
  final bool toggleOnLever;


  SendClockSetCommand(this.timeLeft, this.timeRight, this.leftIsRunning, this.rightIsRunning, this.pause, this.toggleOnLever);

  Future<List<int>> data() async {
    return [
      (timeLeft.inHours),
      (timeLeft.inMinutes % 60),
      (timeLeft.inSeconds % 60),
      (timeRight.inHours),
      (timeRight.inMinutes % 60),
      (timeRight.inSeconds % 60),
      ((leftIsRunning ? 0x01 : 0x00) | (rightIsRunning ? 0x02 : 0x00) | (pause ? 0x04 : 0x00) | (toggleOnLever ? 0x08 : 0x00))
    ];
  }
}