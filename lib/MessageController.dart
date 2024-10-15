import 'package:teste_bluetooth_pi/models/message.dart';

class MessageController {

  sendObtainedMessages(List<Message> messages) {
    print(messages.map((message) => print(message.text)));
  }
}