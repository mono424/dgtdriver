import 'dart:typed_data';
import 'package:dgtdriver/protocol/Command.dart';

abstract class DataCommand<T> extends Command<T> {
  final int _startFlag = 0x05;
  final int _endFlag = 0x00;

  Future<List<int>> data() async {
    return [];
  }

  Future<Uint8List> messageBuilder() async {
    int code = this.code;
    List<int> data = await this.data();
    int msgLen = data.length + 2;

    return Uint8List.fromList([
      code, 
      msgLen,
      _startFlag,
      ...data,
      _endFlag
    ]);
  }
}