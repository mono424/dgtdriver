import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/DataCommand.dart';

class MagicPegasusHandshakeCommand extends DataCommand<void> {
  final int code = 0x63;
  final Answer<void> answer = null;

  final List<int> magicSequence = [
    190, 245, 174, 221, 169, 95, 0
  ];

  Future<List<int>> data() async {
    return magicSequence;
  }
}