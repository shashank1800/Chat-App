import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sample/Objects/ContactObject.dart';
import 'package:sample/Utils/Constants.dart';
import 'package:sample/Utils/Data.dart';
import 'package:sample/screens/ChatScreen.dart';
import '../Utils/AppUISettings.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class FriendList extends StatefulWidget {
  @override
  _FriendListState createState() => _FriendListState();
}

class _FriendListState extends State<FriendList> {
  List<ContactObject> _yourFriends = [];

  @override
  void initState() {
    super.initState();
    getFriendsList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppUISettings.primaryColor,
        title: Text("Friends"),
      ),
      body: Container(
        child: Center(
          child: ListView(
            children: createListTiles(),
          ),
        ),
      ),
    );
  }

  List<Widget> createListTiles() {
    List<Widget> contactsCard = <Widget>[];
    for (ContactObject person in _yourFriends) {
      contactsCard.add(Padding(
        padding: EdgeInsets.all(10),
        child: ListTile(
          dense: true,
          leading: ClipOval(
            child: CachedNetworkImage(
              imageUrl: person.getProfileURL(),
            ),
          ),
          onTap: () => moveToChatScreen(person),
          title: Text(person.getName().toString()),
          trailing: Visibility(
            visible: person.getOnlineStatus(),
            child: CircleAvatar(
              backgroundColor: Colors.greenAccent,
              radius: 10,
            ),
          ),
        ),
      ));
    }
    return contactsCard;
  }

  Future<void> getFriendsList() async {
    List friends = [];
    FirebaseUser user = await _auth.currentUser();
    var documentSnapshot = await Firestore.instance
        .collection("User")
        .document(user.phoneNumber)
        .get();

    if (documentSnapshot.data[Constants.friends] != null)
      friends = documentSnapshot.data[Constants.friends];

    for (String phone in friends) {
      addHimToList(phone);
    }
  }

  Future<void> addHimToList(String number) async {
    var documentSnapshot =
        await Firestore.instance.collection("User").document(number).get();

    ContactObject person = new ContactObject("", "");

    if (documentSnapshot.exists) {
      setState(() {
        person.setName(documentSnapshot.data[Constants.name].toString());
        person.setPhone(number);
        person.setProfileID(documentSnapshot.data[Constants.profileID]);
        person.setProfileURL(documentSnapshot.data[Constants.profileURL]);
        _yourFriends.add(person);
      });
    }

    FirebaseDatabase.instance
        .reference()
        .child("Online")
        .child(number)
        .onValue
        .listen((data) {
      setState(() {
        if (data.snapshot.value != null)
          person.setOnlineStatus(data.snapshot.value);
      });
    });
  }

  void moveToChatScreen(ContactObject person) {
    Data.person = person;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(),
      ),
    );
  }
}
