import 'package:dgtdriver/models/Piece.dart';

abstract class DGTProtocol {
  static const List<String> SQUARES = ['a8', 'b8', 'c8', 'd8', 'e8', 'f8', 'g8', 'h8', 'a7', 'b7', 'c7', 'd7', 'e7', 'f7', 'g7', 'h7', 'a6', 'b6', 'c6', 'd6', 'e6', 'f6', 'g6', 'h6', 'a5', 'b5', 'c5', 'd5', 'e5', 'f5', 'g5', 'h5', 'a4', 'b4', 'c4', 'd4', 'e4', 'f4', 'g4', 'h4', 'a3', 'b3', 'c3', 'd3', 'e3', 'f3', 'g3', 'h3', 'a2', 'b2', 'c2', 'd2', 'e2', 'f2', 'g2', 'h2', 'a1', 'b1', 'c1', 'd1', 'e1', 'f1', 'g1', 'h1'];

  static const Map<int, Piece> PIECES = {
    0x0: null,
    0x1: Piece(notation: 'P', role: 'pawn', color: 'white'),
    0x2: Piece(notation: 'R', role: 'rook', color: 'white'),
    0x3: Piece(notation: 'N', role: 'knight', color: 'white'),
    0x4: Piece(notation: 'B', role: 'bishop', color: 'white'),
    0x5: Piece(notation: 'K', role: 'king', color: 'white'),
    0x6: Piece(notation: 'Q', role: 'queen', color: 'white'),
    0x7: Piece(notation: 'p', role: 'pawn', color: 'black'),
    0x8: Piece(notation: 'r', role: 'rook', color: 'black'),
    0x9: Piece(notation: 'n', role: 'knight', color: 'black'),
    0xa: Piece(notation: 'b', role: 'bishop', color: 'black'),
    0xb: Piece(notation: 'k', role: 'king', color: 'black'),
    0xc: Piece(notation: 'q', role: 'queen', color: 'black'),
    0xd: null,
    /* Magic piece: Draw */
    0xe: null,
    /* Magic piece: White win */
    0xf: null /* Magic piece: Black win */
  };
}