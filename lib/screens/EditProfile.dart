import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sample/Utils/AppUISettings.dart';
import 'package:sample/screens/ImagePickCropCompress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sample/Utils/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController nameController = new TextEditingController();
  final TextEditingController profileIDController = new TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  SharedPreferences prefs;

  String _profileImage = "";
  String _name = "";
  String _profileID = "";
  String _phoneNumber = "";
  File _image;

  @override
  void initState() {
    super.initState();
    updateProfile();
  }

  Future<void> getImage() async {
    final image = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImagePickCropCompress()),
    );
    setState(() {
      _image = image;
      updateProfilePhoto();
    });
  }

  Future<void> setPhoneNumber() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    String phoneNo = user.phoneNumber;

    setState(() {
      this._phoneNumber = phoneNo;
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
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _profileImage,
                      width: 200,
                      height: 200,
                    ),
                  )
                : ClipOval(
                    child: Image.file(
                      _image,
                      width: 200,
                      height: 200,
                    ),
                  ),
            Column(
              children: <Widget>[
                Text(AppUISettings.appName + " ID"),
                ListTile(
                  title: Text(_profileID),
                  trailing: Icon(
                    Icons.edit,
                    color: Colors.blueGrey,
                  ),
                  onTap: () {},
                ),
              ],
            ),
            Column(
              children: <Widget>[
                Text("Phone Number"),
                ListTile(
                  title: Text(_phoneNumber),
                  trailing: Icon(
                    Icons.edit,
                    color: Colors.blueGrey,
                  ),
                  onTap: () {},
                ),
              ],
            ),
            ListTile(
              title: Text(_name),
              trailing: Icon(
                Icons.edit,
                color: Colors.blueGrey,
              ),
              onTap: () => _settingModalBottomSheet,
            ),
          ],
        ),
      ),
    );
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          color: Color(0xFF737373),
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              color: Colors.white,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: TextField(
                    autofocus: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> profileNameNotExist(var profileID) async {
    bool exist = true;
    var data = await Firestore.instance
        .collection(Constants.user)
        .where(Constants.profileID, isEqualTo: profileID)
        .getDocuments();

    if (data.documents.length >= 1 &&
        data.documents[0][Constants.profileID] == profileID) exist = false;

    return exist;
  }

  void updateProfilePhoto() async {
    StorageReference reference =
        FirebaseStorage.instance.ref().child(this._phoneNumber);
    StorageUploadTask uploadTask = reference.putFile(_image);
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        value.ref.getDownloadURL().then((downloadUrl) {
          if (downloadUrl != null) {
            Firestore.instance
                .collection(Constants.user)
                .document(this._phoneNumber)
                .updateData({Constants.profileURL: downloadUrl}).then(
                    (data) async {
              await prefs.setString(Constants.profileURL, downloadUrl);
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

  void updateProfile() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(Constants.profileID)) {
      setState(() {
        _name = prefs.getString(Constants.name);
        _profileID = prefs.getString(Constants.profileID);
        _profileImage = prefs.getString(Constants.profileURL);

        nameController.text = _name;
        profileIDController.text = _profileID;
      });
    } else {
      print("Shared Preference error");
    }
  }
}
