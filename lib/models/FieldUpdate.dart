import 'package:dgtdriver/models/Piece.dart';

enum FieldUpdateAction { pickup, setdown }

class FieldUpdate {
  final String field;
  final Piece piece;

  FieldUpdate({this.field, this.piece});

  String getNotation({bool takes = false, String from = ""}) {
    if (piece == null) return "";
    return piece.notation + from + (takes ? "x" : "") + field;
  }

  @override
  String toString() {
    return field + ": " + piece.toString();
  }
}

class DetailedFieldUpdate extends FieldUpdate {
  final FieldUpdateAction action;

  DetailedFieldUpdate({field, piece, this.action})
      : super(field: field, piece: piece);

  String getNotation({bool takes = false, String from = ""}) {
    if (piece == null || action == FieldUpdateAction.pickup) return "";
    return piece.notation + from + (takes ? "x" : "") + field;
  }

  @override
  String toString() {
    return field +
        ": " +
        piece.toString() +
        (action == FieldUpdateAction.pickup ? " (Pickup)" : " (Set)");
  }
}
