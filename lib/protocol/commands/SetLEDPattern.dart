import 'package:dgtdriver/models/LEDPattern.dart';
import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/DataCommand.dart';

class SetLEDPatternCommand extends DataCommand<void> {
  final int code = 0x60;
  final Answer<void> answer = null;

  final LEDPattern pattern;

  SetLEDPatternCommand(this.pattern);

  Future<List<int>> data() async {
    return [
      pattern.speed.index + 1,
      pattern.repeat.index,
      pattern.brightness.index,
      ...pattern.fields.map((f) => f.index).toList()
    ];
  }
}
