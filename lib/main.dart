import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sample/Utils/AppUISettings.dart';
import './screens/PhoneVerify.dart';
import './screens/LoginData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './screens/Home.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

final FirebaseAuth _auth = FirebaseAuth.instance;

void main() => runApp(MaterialApp(
      home: MyApp(),
      title: AppUISettings.appName,
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    _firebaseMessaging
        .requestNotificationPermissions(const IosNotificationSettings(
      sound: true,
      badge: true,
      alert: true,
      provisional: false,
    ));

    _firebaseMessaging.getToken().then((data) {
      print(data);
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );

    checkUserExists();
    checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.all(15),
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              "assets/app_icon.png",
              height: 150,
              width: 150,
            )
          ],
        ),
      ),
    );
  }

  Future<void> checkUserExists() async {
    final FirebaseUser user = await _auth.currentUser();

    if (user != null && await checkDataExist(user)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } else if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginData()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PhoneVerfy()),
      );
    }
  }

  Future<bool> checkDataExist(var user) async {
    var response = user.phoneNumber;
    var documentRef = Firestore.instance.collection("User").document(response);
    var data = await documentRef.get();
    if (data != null && data.exists) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      prefs.setString("name", data.data["name"]);
      prefs.setString("profileID", data.data["profileID"]);
      prefs.setString("profileURL", data.data["profileURL"]);
      return true;
    } else
      return false;
  }

  void checkPermissions() async {
    Map<PermissionGroup, PermissionStatus> permissions =
        await PermissionHandler()
            .requestPermissions([PermissionGroup.contacts]);
  }
}

Future<void> myBackgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }

  // Or do other work.
}
