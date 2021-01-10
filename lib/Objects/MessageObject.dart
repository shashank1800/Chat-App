import 'ContactObject.dart';

class MessageObject {
  ContactObject person;
  MessageObject(ContactObject person) {
    this.person = person;
  }

  String lastMessage = "";

  void setLastMessage(String message) {
    this.lastMessage = message;
  }

  String getLastMessage() {
    return this.lastMessage;
  }

  ContactObject getContactObject() {
    return this.person;
  }
}
