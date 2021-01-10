import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:sample/screens/ChatScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Objects/ContactObject.dart';
import '../Utils/Constants.dart';
import '../Utils/Data.dart';
import '../Utils/AppUISettings.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class ContactList extends StatefulWidget {
  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  List<ContactObject> _doteUserList = [];
  List _yourFriends = [];
  SharedPreferences prefs;
  @override
  void initState() {
    super.initState();
    getDoteUsers(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppUISettings.primaryColor,
        title: Text("Contacts"),
        actions: <Widget>[
          FlatButton(
            onPressed: () => getDoteUsers(true),
            child: Text(
              "Refresh",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          )
        ],
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

  void getDoteUsers(bool isRefresh) async {
    prefs = await SharedPreferences.getInstance();
    FirebaseUser user = await _auth.currentUser();
    var yourPhoneNo = user.phoneNumber;

    _yourFriends = await getFriendsList();
    List<ContactObject> phoneBook = await getAllContactList();

    //Add notDoteUserToReduceTheNumberOfQuery
    if (prefs.containsKey(Constants.contactList) && !isRefresh) {
      List<String> notDoteUser = prefs.getStringList(Constants.contactList);
      for (ContactObject person in phoneBook) {
        if (!notDoteUser.contains(person.getPhone()) &&
            !_yourFriends.contains(person.getPhone()) &&
            person.getPhone().compareTo(yourPhoneNo) != 0) {
          checkPhoneInDatabase(person);
        }
      }
    } else {
      prefs.setStringList(Constants.contactList, []);
      _doteUserList = [];

      for (ContactObject person in phoneBook) {
        if (!_yourFriends.contains(person.getPhone()) &&
            person.getPhone().compareTo(yourPhoneNo) != 0) {
          checkPhoneInDatabase(person);
        }
      }
    }
  }

  void checkPhoneInDatabase(ContactObject person) async {
    var documentSnapshot = await Firestore.instance
        .collection("User")
        .document(person.getPhone())
        .get();

    if (documentSnapshot.exists) {
      person.setProfileID(documentSnapshot.data[Constants.profileID]);
      person.setProfileURL(documentSnapshot.data[Constants.profileURL]);
      // add
      setState(() {
        _doteUserList.add(person);
      });
    } else {
      List<String> nonFriends = prefs.getStringList(Constants.contactList);
      nonFriends.add(person.getPhone());
      prefs.setStringList(Constants.contactList, nonFriends);
    }
  }

  Future<List<ContactObject>> getAllContactList() async {
    Iterable<Contact> contacts =
        await ContactsService.getContacts(withThumbnails: false);

    List<ContactObject> contactList = [];

    List<String> list = [];

    contacts.forEach((contact) {
      RegExp exp = new RegExp(r"[0-9]{7}$");

      String name = contact.displayName;
      contact.phones.forEach((number) {
        if (exp.hasMatch(number.value) && !list.contains(number.value)) {
          list.add(number.value);
          contactList.add(new ContactObject(name, number.value));
        }
      });
    });

    return contactList;
  }

  List<Widget> createListTiles() {
    List<Widget> contactsCard = <Widget>[];
    for (ContactObject person in _doteUserList) {
      contactsCard.add(
        new ListTile(
          leading: (person.getProfileID().isEmpty)
              ? CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person_add),
                )
              : ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: person.getProfileURL(),
                  ),
                ),
          onTap: () => showProfileInDialog(person),
          title: new Text(person.getName()),
          subtitle: Text(person.getPhone()),
          enabled: (person.getProfileID().isEmpty) ? false : true,
        ),
      );
    }
    return contactsCard;
  }

  showProfileInDialog(ContactObject person) async {
    await showDialog(
      context: this.context,
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Wrap(
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          direction: Axis.vertical,
          children: <Widget>[
            Container(
              child: CachedNetworkImage(
                imageUrl: person.getProfileURL(),
                width: 280,
                height: 280,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(5),
              child: Text(
                person.getName(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(5),
              child: Text(
                person.getProfileID(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            (person.getProfileID().isNotEmpty && person.isHeFriend == false)
                ? Container(
                    margin: EdgeInsets.all(10),
                    child: RaisedButton(
                      onPressed: () => addHimAsAFriend(person),
                      child: Text("Add Friend"),
                    ),
                  )
                : Container(
                    margin: EdgeInsets.all(10),
                    child: RaisedButton(
                      onPressed: () => moveToChatScreen(person),
                      child: Text("Message"),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  void addHimAsAFriend(ContactObject person) async {
    FirebaseUser me = await _auth.currentUser();

    var documentRef =
        Firestore.instance.collection("User").document(me.phoneNumber);
    var datasnap = await documentRef.get();
    if (datasnap != null && datasnap.exists) {
      List friends = [];
      if (datasnap.data[Constants.yourFriendRequest] != null)
        friends = datasnap.data[Constants.yourFriendRequest];

      if (!friends.contains(person.getPhone())) friends.add(person.getPhone());

      await Firestore.instance
          .collection("User")
          .document(me.phoneNumber)
          .updateData({Constants.yourFriendRequest: friends});
    }

    documentRef =
        Firestore.instance.collection("User").document(person.getPhone());

    datasnap = await documentRef.get();

    if (datasnap != null && datasnap.exists) {
      List friends = [];
      if (datasnap.data[Constants.friendFriendRequest] != null) {
        friends = datasnap.data[Constants.friendFriendRequest];
      }
      if (!friends.contains(me.phoneNumber)) {
        friends.add(me.phoneNumber);
      }
      await Firestore.instance
          .collection("User")
          .document(person.getPhone())
          .updateData({Constants.friendFriendRequest: friends});
    }

    Navigator.pop(context);
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

  Future<List> getFriendsList() async {
    List friends = [];
    FirebaseUser user = await _auth.currentUser();
    var documentSnapshot = await Firestore.instance
        .collection("User")
        .document(user.phoneNumber)
        .get();

    if (documentSnapshot.data[Constants.friends] != null)
      friends = documentSnapshot.data[Constants.friends];
    return friends;
  }
}
