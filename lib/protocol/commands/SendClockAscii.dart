import 'package:dgtdriver/protocol/ClockAnswerType.dart';
import 'package:dgtdriver/protocol/ClockCommand.dart';

class SendClockAsciiCommand extends ClockCommand {
  final int code = 0x0c;
  final ClockAnswerType answerType = ClockAnswerType.displayAck;
  final String text;
  final Duration beep;

  SendClockAsciiCommand(this.text, this.beep);

  Future<List<int>> data() async {
    String eightByteText = text.padRight(8, " ").substring(0, 8);
    return [
      ...Iterable.generate(8, (x) => eightByteText.codeUnitAt(x)),
      (beep.inMilliseconds ~/ 64)
    ];
  }
}