import 'package:dgtdriver/protocol/Answer.dart';
import 'package:dgtdriver/protocol/DataCommand.dart';

class AuthorizeWithDeveloperKey extends DataCommand<void> {
  final int code = 0x63;
  final Answer<void> answer = null;

  final List<int> developerKey;

  AuthorizeWithDeveloperKey(this.developerKey);

  Future<List<int>> data() async {
    return [...developerKey, 0];
  }
}