import 'package:dgtdriver/models/Piece.dart';
import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/Command.dart';
import 'package:dgtdriver/protocol/DGTProtocol.dart';

class GetBoardCommand extends Command<Map<String, Piece>> {
  final int code = 0x42;
  final Answer<Map<String, Piece>> answer;
  final List<String> squares;

  GetBoardCommand(this.squares) : answer = GetBoardAnswer(squares);
}

class GetBoardAnswer extends Answer<Map<String, Piece>> {
  final int code = 0x06;

  final List<String> squares;

  GetBoardAnswer(this.squares);

  @override
  Map<String, Piece> process(List<int> msg) {
    Map<String, Piece> board = Map<String, Piece>();
    for (int i = 0; i < 64; i++) {
      board[squares[i]] = DGTProtocol.PIECES[msg[i]];
    }
    return board;
  }
}