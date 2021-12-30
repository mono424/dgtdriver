import 'dart:typed_data';

import 'package:dgtdriver/DGTCommunicationClient.dart';
import 'package:dgtdriver/DGTMessage.dart';
import 'package:dgtdriver/protocol/Answer.dart';

abstract class Command<T> {
  int code;
  Answer<T> answer;

  Future<Uint8List> messageBuilder() async {
    return Uint8List.fromList([code]);
  }

  Future<void> send(DGTCommunicationClient client) async {
    print(await messageBuilder());
    await client.send(await messageBuilder());
  }

  Future<T> request(DGTCommunicationClient client, Stream<DGTMessage> inputStream) async {
    Future<T> result = getReponse(inputStream);
    await send(client);
    return result;
  }

  Future<T> getReponse(Stream<DGTMessage> inputStream) async {
    if (answer == null) return null;
    DGTMessage message = await inputStream
        .firstWhere((DGTMessage msg) => msg.getCode() == answer.code);
    return answer.process(message.getMessage());
  }
}