import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Utils/Constants.dart';
import '../Utils/AppUISettings.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List _listOfFriendRequest = [];

  @override
  void initState() {
    super.initState();
    getFriendRequestList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppUISettings.primaryColor,
        title: Text("Notification"),
      ),
      body: Container(
        child: ListView(
          children: showFriendRequest(),
        ),
      ),
    );
  }

  List<Widget> showFriendRequest() {
    List<Widget> friendRequestCard = <Widget>[];

    for (dynamic friend in _listOfFriendRequest) {
      friendRequestCard.add(Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 70,
                margin: const EdgeInsets.all(10),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: friend[Constants.profileURL],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(10),
                child: Wrap(
                  direction: Axis.vertical,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(4),
                      child: Text(
                        friend[Constants.name],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(4),
                      child: Text(
                        friend[Constants.profileID],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                child: RaisedButton(
                  onPressed: () => deleteFriendRequest(friend),
                  child: Text("Delete"),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: RaisedButton(
                  onPressed: () => acceptFriendRequest(friend),
                  child: Text(
                    "Accept",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  color: Colors.lightBlueAccent,
                ),
              ),
            ],
          ),
          Divider(
            color: Colors.black45,
            thickness: 1,
          )
        ],
      ));
    }
    return friendRequestCard;
  }

  Future<String> getPhoneNumber() async {
    FirebaseAuth _auth = FirebaseAuth.instance;
    return _auth.currentUser().then((user) {
      return user.phoneNumber;
    });
  }

  acceptFriendRequest(dynamic friend) async {
    setState(() {
      _listOfFriendRequest.remove(friend);
    });

    var yourPhoneNumber = await getPhoneNumber();

    // Add friend to Friends List of Yours
    var documentRef =
        Firestore.instance.collection("User").document(yourPhoneNumber);
    var datasnap = await documentRef.get();
    if (datasnap != null && datasnap.exists) {
      List<dynamic> friends = [];
      if (datasnap.data[Constants.friends] != null)
        friends = datasnap.data[Constants.friends];
      friends.add(friend[Constants.phoneNumber]);
      await Firestore.instance
          .collection("User")
          .document(await getPhoneNumber())
          .updateData({Constants.friends: friends});
    }

    // Add friend to Friends List of Friend
    documentRef = Firestore.instance
        .collection("User")
        .document(friend[Constants.phoneNumber]);
    datasnap = await documentRef.get();
    if (datasnap != null && datasnap.exists) {
      List<dynamic> friends = [];
      if (datasnap.data[Constants.friends] != null)
        friends = datasnap.data[Constants.friends];
      friends.add(yourPhoneNumber);
      await Firestore.instance
          .collection("User")
          .document(friend[Constants.phoneNumber])
          .updateData({Constants.friends: friends});
    }

    //Delete phoneNumber from friendFriendRequest of Yours
    documentRef =
        Firestore.instance.collection("User").document(yourPhoneNumber);
    datasnap = await documentRef.get();
    if (datasnap != null && datasnap.exists) {
      List<dynamic> friends = [];
      if (datasnap.data[Constants.friendFriendRequest] != null)
        friends = datasnap.data[Constants.friendFriendRequest];
      friends.remove(friend[Constants.phoneNumber]);
      await Firestore.instance
          .collection("User")
          .document(await getPhoneNumber())
          .updateData({Constants.friendFriendRequest: friends});
    }

    //Delete phoneNumber from yourFriendRequest of Friend
    documentRef = Firestore.instance
        .collection("User")
        .document(friend[Constants.phoneNumber]);
    datasnap = await documentRef.get();

    if (datasnap != null && datasnap.exists) {
      List friends = [];
      if (datasnap.data[Constants.yourFriendRequest] != null) {
        friends = datasnap.data[Constants.yourFriendRequest];
      }
      friends.remove(yourPhoneNumber);
      await Firestore.instance
          .collection("User")
          .document(friend[Constants.phoneNumber])
          .updateData({Constants.yourFriendRequest: friends});
    }
  }

  deleteFriendRequest(dynamic friend) async {
    setState(() {
      _listOfFriendRequest.remove(friend);
    });
    var yourPhoneNumber = await getPhoneNumber();
    var documentRef =
        Firestore.instance.collection("User").document(yourPhoneNumber);
    var datasnap = await documentRef.get();
    if (datasnap != null && datasnap.exists) {
      List<dynamic> friends = [];
      if (datasnap.data[Constants.friendFriendRequest] != null)
        friends = datasnap.data[Constants.friendFriendRequest];
      friends.remove(friend[Constants.phoneNumber]);
      await Firestore.instance
          .collection("User")
          .document(await getPhoneNumber())
          .updateData({Constants.friends: friends});
    }
  }

  void getFriendRequestList() async {
    List<dynamic> _listOfFriendRequestPhoneNumber = [];
    var docRef =
        Firestore.instance.collection("User").document(await getPhoneNumber());

    var snapshot = await docRef.get();

    if (snapshot.exists) {
      setState(() {
        if (snapshot.data[Constants.friendFriendRequest] != null)
          _listOfFriendRequestPhoneNumber =
              snapshot.data[Constants.friendFriendRequest];
      });
    }

    for (String phoneNumber in _listOfFriendRequestPhoneNumber)
      addPersonDataToGlobalArray(phoneNumber);
  }

  void addPersonDataToGlobalArray(String phoneNumber) async {
    Map person = HashMap<String, String>();

    var docRef = Firestore.instance.collection("User").document(phoneNumber);
    var snapshot = await docRef.get();

    if (snapshot.exists) {
      person[Constants.name] = snapshot.data[Constants.name];
      person[Constants.profileID] = snapshot.data[Constants.profileID];
      person[Constants.profileURL] = snapshot.data[Constants.profileURL];
      person[Constants.phoneNumber] = phoneNumber;
      setState(() {
        _listOfFriendRequest.add(person);
      });
    }
  }
}
