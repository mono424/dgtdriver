import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/Command.dart';

class SendUpdateBoardCommand extends Command<void> {
  final int code = 0x44;
  final Answer<void> answer = null;
}