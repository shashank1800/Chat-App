// import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sample/Objects/ContactObject.dart';
import 'package:sample/Objects/MessageObject.dart';
import 'package:sample/Utils/Constants.dart';
import 'package:sample/Utils/Data.dart';
import 'package:sample/screens/FriendList.dart';
import 'package:sample/screens/NotificationScreen.dart';
import 'ChatScreen.dart';
import 'ContactList.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'EditProfile.dart';
import '../main.dart';
import '../Utils/AppUISettings.dart';

FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseDatabase database = FirebaseDatabase.instance;

enum MenuOptionItems { logout }

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _profileName = "";
  String _profileID = "";
  String _profileImage = "";

  List<MessageObject> _yourFriends = [];

  @override
  void initState() {
    super.initState();
    updateProfile();
    getFriendMessageList();
    setUserOnline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppUISettings.primaryColor,
        title: Text(AppUISettings.appName),
        actions: <Widget>[
          IconButton(
            onPressed: () => moveToFriendRequestScreen(),
            icon: Icon(Icons.notifications_none),
          ),
          PopupMenuButton<MenuOptionItems>(
            onSelected: (MenuOptionItems result) {
              menuItemOptionOnSelected(result.index);
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<MenuOptionItems>>[
              const PopupMenuItem<MenuOptionItems>(
                value: MenuOptionItems.logout,
                child: Text('Logout'),
              ),
            ],
          )
        ],
      ),
      drawer: Drawer(
        child: _drawer(),
      ),
      floatingActionButton: Container(
          margin: const EdgeInsets.all(10),
          child: Wrap(
            children: <Widget>[
              FloatingActionButton(
                onPressed: () => showContactList(context),
                child: Icon(Icons.people_outline),
                tooltip: "Contacts",
                backgroundColor: AppUISettings.primaryColor,
              ),
            ],
          )),
      body: Column(
        children: friendMessageList(),
      ),
    );
  }

  Widget _drawer() {
    return Container(
      child: Column(
        children: <Widget>[
          SafeArea(
            child: Column(
              children: <Widget>[
                _profileImage == null
                    ? Container(
                        height: 120,
                        width: 120,
                        margin: const EdgeInsets.fromLTRB(0, 40, 0, 15),
                        child: CircleAvatar(),
                      )
                    : Container(
                        height: 120,
                        margin: const EdgeInsets.fromLTRB(0, 40, 0, 15),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _profileImage,
                          ),
                        ),
                      ),
                Container(
                  margin: const EdgeInsets.all(5),
                  child: Text(
                    _profileName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  child: Text(
                    _profileID,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  child: OutlineButton(
                    onPressed: () => moveToEditProfileScreen(),
                    child: Text("Edit Profile"),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.people_outline,
                            size: 28, color: Colors.green),
                        title: Text(
                          "Friends",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        onTap: () => showFriendList(),
                      ),
                      ListTile(
                        leading: Icon(Icons.chat_bubble_outline,
                            size: 28, color: Colors.blue),
                        title: Text(
                          "Feedback",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.help_outline,
                            size: 28, color: Colors.red),
                        title: Text(
                          "Help",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> friendMessageList() {
    List<Widget> friendMessage = <Widget>[];
    for (MessageObject messageObject in _yourFriends) {
      ContactObject person = messageObject.getContactObject();
      friendMessage.add(Padding(
        padding: EdgeInsets.all(10),
        child: ListTile(
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: new Border.all(
                color: Colors.blueGrey,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: person.getProfileURL(),
              ),
            ),
          ),
          onTap: () => moveToChatScreen(person),
          title: Text(
            person.getName(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            messageObject.getLastMessage(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ));
    }
    return friendMessage;
  }

  Future<void> getFriendMessageList() async {
    List friends = [];
    FirebaseUser user = await _auth.currentUser();
    var documentSnapshot = await Firestore.instance
        .collection(Constants.user)
        .document(user.phoneNumber)
        .get();

    if (documentSnapshot.data[Constants.friends] != null)
      friends = documentSnapshot.data[Constants.friends];

    for (String phone in friends) {
      addHimToList(phone, user.phoneNumber);
    }
  }

  Future<void> addHimToList(
      String friendPhoneNumber, String yourPhoneNumber) async {
    ContactObject person = new ContactObject("", "");
    var documentSnapshot = await Firestore.instance
        .collection(Constants.user)
        .document(friendPhoneNumber)
        .get();

    String mergedChatKey = "";
    if (yourPhoneNumber.compareTo(friendPhoneNumber) > 0)
      mergedChatKey =
          yourPhoneNumber.substring(1) + friendPhoneNumber.substring(1);
    else {
      mergedChatKey =
          friendPhoneNumber.substring(1) + yourPhoneNumber.substring(1);
    }

    MessageObject messageObject = new MessageObject(person);

    if (documentSnapshot.exists) {
      setState(() {
        person.setName(documentSnapshot.data[Constants.name]);
        person.setPhone(friendPhoneNumber);
        person.setProfileID(documentSnapshot.data[Constants.profileID]);
        person.setProfileURL(documentSnapshot.data[Constants.profileURL]);
        _yourFriends.add(messageObject);
      });
    }

    Firestore.instance
        .collection(Constants.message)
        .document(mergedChatKey)
        .collection("Chats")
        .orderBy(Constants.timeStamp, descending: true)
        .limit(1)
        .snapshots()
        .listen((data) {
      print(data.documents[0].data[Constants.text]);
      setState(() {
        if (yourPhoneNumber
                .compareTo(data.documents[0].data[Constants.phoneNumber]) ==
            0)
          messageObject.setLastMessage(
              "You : " + data.documents[0].data[Constants.text]);
        else
          messageObject.setLastMessage(data.documents[0].data[Constants.text]);
      });
    });
  }

  void updateProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("profileID")) {
      String profileName = prefs.getString("name");
      String profileID = prefs.getString("profileID");
      String profileImage = prefs.getString("profileURL");
      setState(() {
        _profileName = profileName;
        _profileID = profileID;
        _profileImage = profileImage;
      });
    } else {
      print("Shared Preference error");
    }
  }

  Future<String> getUserPhone() async {
    return _auth.currentUser().then((user) {
      return user.phoneNumber;
    });
  }

  void setUserOnline() async {
    var phoneNumber = await getUserPhone();
    database.reference().child("Online").child(phoneNumber).set(true);
    database
        .reference()
        .child("Online")
        .child(phoneNumber)
        .onDisconnect()
        .set(false);
  }

  //All navigations here
  showContactList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactList()),
    );
  }

  moveToFriendRequestScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(),
      ),
    );
  }

  menuItemOptionOnSelected(int id) {
    switch (id) {
      case 0:
        _auth.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
        break;
    }
  }

  moveToEditProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfile(),
      ),
    );
  }

  showFriendList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FriendList()),
    );
  }

  void moveToChatScreen(ContactObject person) {
    Data.person = person;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(),
      ),
    );
  }
}

// Column(
//                     children: <Widget>[
//                       GestureDetector(
//                         onTap: () {},
//                         child: Row(
//                           children: <Widget>[
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 5),
//                               child: Icon(
//                                 Icons.fiber_smart_record,
//                                 size: 28,
//                                 color: Colors.blue,
//                               ),
//                             ),
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 5),
//                               child: Text(
//                                 "Feedback",
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () {},
//                         child: Row(
//                           children: <Widget>[
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 5),
//                               child: Icon(
//                                 Icons.info,
//                                 size: 28,
//                                 color: Colors.green,
//                               ),
//                             ),
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 5),
//                               child: Text(
//                                 "About Us",
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () {},
//                         child: Row(
//                           children: <Widget>[
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 5),
//                               child: Icon(
//                                 Icons.help,
//                                 size: 28,
//                                 color: Colors.redAccent.shade200,
//                               ),
//                             ),
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 5),
//                               child: Text(
//                                 "Help",
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
