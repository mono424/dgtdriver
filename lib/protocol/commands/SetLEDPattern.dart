import 'package:dgtdriver/models/LEDPattern.dart';
import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/DataCommand.dart';

class SetLEDPatternCommand extends DataCommand<void> {
  final int code = 0x60;
  final Answer<void> answer = null;

  final int startFlag = 0x05;
  final int endFlag = 0x00;
  final LEDPattern pattern;

  SetLEDPatternCommand(this.pattern);

  Future<List<int>> data() async {
    return [
      startFlag,
      pattern.speed.index + 1,
      pattern.repeat.index,
      pattern.brightness.index,
      ...pattern.fields.map((f) => f.index).toList(),
      endFlag
    ];
  }
}
