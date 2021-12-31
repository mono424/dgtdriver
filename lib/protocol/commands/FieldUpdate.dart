import 'package:dgtdriver/models/FieldUpdate.dart';
import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/DGTProtocol.dart';

class FieldUpdateAnswer extends Answer<FieldUpdate> {
  final int code = 0x0e;
  final List<String> squares;

  FieldUpdateAnswer(this.squares);

  FieldUpdate process(List<int> msg) {
    return FieldUpdate(
        field: squares[msg[0]], piece: DGTProtocol.PIECES[msg[1]]);
  }
}