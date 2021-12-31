import 'dart:typed_data';
import 'package:dgtdriver/protocol/Command.dart';

abstract class DataCommand<T> extends Command<T> {
  Future<List<int>> data() async {
    return [];
  }

  Future<Uint8List> messageBuilder() async {
    int code = this.code;
    List<int> data = await this.data();
    int msgLen = data.length;

    return Uint8List.fromList([
      code, 
      msgLen,
      ...data,
    ]);
  }
}