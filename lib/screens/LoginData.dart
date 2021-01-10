import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sample/Utils/Constants.dart';
import './Home.dart';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

class LoginData extends StatefulWidget {
  @override
  _LoginDataState createState() => _LoginDataState();
}

class _LoginDataState extends State<LoginData> {
  final TextEditingController nameController = new TextEditingController();
  final TextEditingController profileIDController = new TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String _token = "";

  File _image;

  Future getImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.getToken().then((data) {
      _token = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? CircleAvatar(
                    radius: 100,
                  )
                : ClipOval(
                    child: Image.file(
                      _image,
                      width: 200,
                      height: 200,
                    ),
                  ),
            Container(
              margin: const EdgeInsets.all(15),
              child: TextField(
                controller: nameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: "Name",
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(15),
              child: TextField(
                controller: profileIDController,
                decoration: InputDecoration(
                  labelText: "Profile ID",
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(15),
              child: RaisedButton(
                onPressed: () => submitHandler(context),
                child: Text("Submit"),
                color: Colors.blue,
                textColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  submitHandler(BuildContext context) async {
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    var name = nameController.text;
    var profileID = profileIDController.text;

    if ((firebaseUser != null) &&
        profileID.isNotEmpty &&
        name.isNotEmpty &&
        _image != null) {
      if (await profileNameNotExist(profileID)) {
        updateDataInFirebase(firebaseUser.phoneNumber, name, profileID);
      } else {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Profile Id already exists'),
          duration: Duration(seconds: 2),
        ));
      }
    } else {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Fields should not be empty'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<bool> profileNameNotExist(var profileID) async {
    bool exist = true;
    var data = await Firestore.instance
        .collection("User")
        .where(Constants.profileID, isEqualTo: profileID)
        .getDocuments();

    if (data.documents.length >= 1 &&
        data.documents[0][Constants.profileID] == profileID) exist = false;

    return exist;
  }

  void updateDataInFirebase(
      String phoneNo, String name, String profileID) async {
    StorageReference reference = FirebaseStorage.instance.ref().child(phoneNo);
    StorageUploadTask uploadTask = reference.putFile(_image);
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        value.ref.getDownloadURL().then((downloadUrl) {
          String photoUrl = downloadUrl;
          if (photoUrl != null) {
            Firestore.instance.collection("User").document(phoneNo).setData({
              Constants.profileID: profileID,
              Constants.name: name,
              Constants.profileURL: photoUrl,
              Constants.tokenID: _token
            }).then((data) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString(Constants.name, name);
              await prefs.setString(Constants.profileID, profileID);
              await prefs.setString(Constants.profileURL, photoUrl);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              );
            });
          } else {
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('Internet Problem Occured'),
              duration: Duration(seconds: 2),
            ));
          }
        });
      }
    });
  }
}
