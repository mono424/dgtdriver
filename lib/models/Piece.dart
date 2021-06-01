class Piece {
  final String notation;
  final String role;
  final String color;
  const Piece({this.notation, this.role, this.color});

  @override
  String toString() {
    return role + "(" + color + ")";
  }

  Piece clone() {
    return new Piece(notation: notation, role: role, color: color);
  }

  static bool equal(Piece a, Piece b) {
    if (a == null && b == null) return true;
    if (a == null && b != null) return false;
    if (a != null && b == null) return false;
    return a.role == b.role && a.color == b.color;
  }
}
