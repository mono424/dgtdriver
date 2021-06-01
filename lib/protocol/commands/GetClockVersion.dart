import 'package:dgtdriver/protocol/ClockAnswerType.dart';
import 'package:dgtdriver/protocol/ClockCommand.dart';

class GetClockVersionCommand extends ClockCommand {
  final int code = 0x09;
  final ClockAnswerType answerType = ClockAnswerType.versionAck;
}