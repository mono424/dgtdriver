import 'package:dgtdriver/models/BatteryStatus.dart';
import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/Command.dart';
import 'package:dgtdriver/protocol/commands/BatteryUpdate.dart';

class SendUpdateBatteryCommand extends Command<void> {
  final int code = 0x4C;
  final Answer<BatteryStatus> answer = BatteryUpdateAnswer();
}
