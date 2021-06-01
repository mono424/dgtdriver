import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/Command.dart';

/*
 * Board will sent Board & Clock Updates
 */
class SendUpdateNiceCommand extends Command<void> {
  final int code = 0x4b;
  final Answer<void> answer = null;
}