import 'dart:typed_data';

import 'package:dgtdriver/models/FieldUpdate.dart';
import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/DGTProtocol.dart';

class FieldUpdateAnswer extends Answer<FieldUpdate> {
  final int code = 0x0e;

  FieldUpdate process(List<int> msg) {
    return FieldUpdate(
        field: DGTProtocol.squares[msg[0]], piece: DGTProtocol.PIECES[msg[1]]);
  }
}