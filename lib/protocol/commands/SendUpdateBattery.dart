import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/Command.dart';

class SendUpdateBatteryCommand extends Command<void> {
  final int code = 0x4C;
  final Answer<void> answer = null;
}
