import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sample/Objects/ContactObject.dart';
import 'package:flutter/rendering.dart';
import 'package:sample/Utils/Constants.dart';
import 'package:sample/Utils/Data.dart';
import 'package:sample/screens/ViewProfile.dart';
import '../Utils/AppUISettings.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _messageTextController = new TextEditingController();

  List<TextEditingController> controllers = new List<TextEditingController>();

  ContactObject _person;
  List _messageList = [];
  String _mergedChatKey = "";
  String _yourPhoneNo = "";
  String _encryptedMessage = "";

  @override
  void initState() {
    super.initState();

    _person = Data.person;

    int prevLen = 0;
    _messageTextController.addListener(() {
      if (prevLen == _messageTextController.text.length + 1)
        _encryptedMessage += '*';
      else {
        _encryptedMessage += _messageTextController.text
            .substring(prevLen, _messageTextController.text.length);
        print(_encryptedMessage);
      }
      prevLen = _messageTextController.text.length;
    });

    getChatFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppUISettings.primaryColor,
        title: Text(_person.getName()),
        actions: <Widget>[
          FlatButton(
            onPressed: () => moveToViewProfilePage(),
            child: Text(
              "View Profile",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: ListView(
                reverse: true,
                children: showMessageInList(),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              color: Colors.lightBlue.shade100,
            ),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: TextField(
                      controller: _messageTextController,
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                      decoration: new InputDecoration(
                        hintText: 'Message..',
                        focusColor: Colors.white,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                FlatButton(
                  onPressed: () => sendMessage(_messageTextController.text),
                  child: Text("Send"),
                  color: Colors.blue,
                  padding: EdgeInsets.all(25),
                  textColor: Colors.white,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<Widget> showMessageInList() {
    List<Widget> messageCard = <Widget>[];

    int index = 0;
    for (dynamic message in _messageList) {
      if (controllers.length <= _messageList.length) {
        final chatText = TextEditingController();
        controllers.add(chatText);
      }

      messageCard.add((message[Constants.phoneNumber] == _yourPhoneNo)
          ? messageCard1(message, index)
          : messageCard2(message, index));
      index++;
    }
    return messageCard;
  }

  getChatFromDatabase() async {
    String friendPhoneNumber = _person.getPhone().substring(1);

    if (_yourPhoneNo.isEmpty) {
      FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
      setState(() {
        _yourPhoneNo = firebaseUser.phoneNumber;
      });
    }

    String yourPhoneNumber = _yourPhoneNo.substring(1);

    if (yourPhoneNumber.compareTo(friendPhoneNumber) > 0)
      _mergedChatKey = yourPhoneNumber + friendPhoneNumber;
    else {
      _mergedChatKey = friendPhoneNumber + yourPhoneNumber;
    }

    Query messageDoc = Firestore.instance
        .collection("Message")
        .document(_mergedChatKey)
        .collection("Chats")
        .orderBy(Constants.timeStamp, descending: true)
        .limit(20);
    messageDoc.snapshots().listen((querySnap) {
      controllers.clear();
      _messageList = [];
      querySnap.documents.forEach((snap) {
        setState(() {
          _messageList.add(snap.data);
        });
      });
    });
  }

  void sendMessage(String message) async {
    _messageTextController.clear();

    var encryptedMessage = "";
    encryptedMessage = _encryptedMessage;
    _encryptedMessage = "";

    if (message.isNotEmpty) {
      var timeStamp = new DateTime.now().millisecondsSinceEpoch;
      Firestore.instance
          .collection("Message")
          .document(_mergedChatKey)
          .collection("Chats")
          .add({
        Constants.timeStamp: timeStamp,
        Constants.text: message,
        Constants.phoneNumber: _yourPhoneNo,
        Constants.friendPhoneNumber: _person.getPhone(),
        Constants.seen: false,
        Constants.encryptedMessage: encryptedMessage
      });
    }
  }

  Widget messageCard1(dynamic message, index) {
    final chatKey = controllers[index];

    return GestureDetector(
      onLongPress: () => animateThisMessage(
          message[Constants.encryptedMessage].toString(), controllers[index]),
      child: Container(
        color: Colors.white10,
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade700,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                padding: EdgeInsets.all(6),
                margin: EdgeInsets.fromLTRB(40, 2, 15, 2),
                child: Text(
                  (chatKey.text).isEmpty
                      ? message[Constants.text]
                      : chatKey.text,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget messageCard2(dynamic message, index) {
    final chatKey = controllers[index];
    return GestureDetector(
      onLongPress: () => animateThisMessage(
          message[Constants.encryptedMessage].toString(), controllers[index]),
      child: Container(
        color: Colors.white10,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent.shade200,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                padding: EdgeInsets.all(6),
                margin: EdgeInsets.fromLTRB(15, 2, 40, 2),
                child: Text(
                  (chatKey.text).isEmpty
                      ? message[Constants.text]
                      : chatKey.text,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  animateThisMessage(message, chatText) async {
    print(message);
    var animatedText = "";
    var clearChar = '*';
    int popCount = 0;

    for (int i = 0; i < message.length; i++) {
      if (message[i] == clearChar) {
        popCount++;
        // animatedText += message[i];
      } else if (popCount != 0) {
        if (animatedText.length > 0)
          animatedText = animatedText.substring(0, animatedText.length - 1);
        i--;
        popCount--;
      } else {
        animatedText += message[i];
      }
      setState(() {
        chatText.text = animatedText;
        print(animatedText);
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      chatText.text = "";
      print(animatedText);
    });
  }

  moveToViewProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfile(
          text: _person.getProfileID(),
        ),
      ),
    );
  }
}
