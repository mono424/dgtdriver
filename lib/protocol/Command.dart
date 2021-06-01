import 'package:dgtdriver/DGTCommunicationClient.dart';
import 'package:dgtdriver/DGTMessage.dart';
import 'package:dgtdriver/protocol/Answer.dart';

abstract class Command<T> {
  int code;
  Answer<T> answer;

  Future<List<int>> messageBuilder() async {
    return [code];
  }

  Future<void> send(DGTCommunicationClient characteristic) async {
    await characteristic.send(await messageBuilder());
  }

  Future<T> request(DGTCommunicationClient characteristic, Stream<DGTMessage> inputStream) async {
    Future<T> result = getReponse(inputStream);
    await send(characteristic);
    return result;
  }

  Future<T> getReponse(Stream<DGTMessage> inputStream) async {
    if (answer == null) return null;
    DGTMessage message = await inputStream
        .firstWhere((DGTMessage msg) => msg.getCode() == answer.code);
    return answer.process(message.getMessage());
  }
}