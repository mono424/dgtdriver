import 'package:dgtdriver/models/FieldUpdate.dart';
import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/DGTProtocol.dart';

class FieldUpdateAnswer extends Answer<FieldUpdate> {
  final int code = 0x0e;

  FieldUpdateAnswer();

  FieldUpdate process(List<int> msg) {
    return FieldUpdate(
        field: DGTProtocol.SQUARES[msg[0]], piece: DGTProtocol.PIECES[msg[1]]);
  }
}