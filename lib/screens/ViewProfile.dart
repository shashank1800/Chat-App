import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sample/Utils/Constants.dart';
import '../Utils/AppUISettings.dart';

class ViewProfile extends StatefulWidget {
  final String text;
  ViewProfile({Key key, @required this.text}) : super(key: key);

  @override
  _ViewProfileState createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  String _name = "";
  String _profileID = "";
  String _profileURL = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppUISettings.primaryColor,
        title: Text("Profile"),

      ),
      body: (_name.isEmpty)
          ? getContainer(context)
          : Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width / 2,
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: new Border.all(
                        color: Colors.blueGrey,
                        width: 5,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _profileURL,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      _name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      _profileID,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      children: <Widget>[
                        RaisedButton(
                          onPressed: () {},
                          child: Text("Add Friend"),
                        ),
                        RaisedButton(
                          onPressed: () {},
                          child: Text("Undu Request"),
                        ),
                        RaisedButton(
                          onPressed: () {},
                          child: Text("Delete Request"),
                        ),
                        RaisedButton(
                          onPressed: () {},
                          child: Text("Unfriend"),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget getContainer(BuildContext context) {
    _profileID = widget.text;
    print(_profileID);
    getDetailsOfPerson();
    return Container();
  }

  void getDetailsOfPerson() async {
    var data = await Firestore.instance
        .collection("User")
        .where(Constants.profileID, isEqualTo: _profileID)
        .getDocuments();

    if (data.documents.length == 1) {
      var personData = data.documents[0].data;
      setState(() {
        _name = personData[Constants.name];
        _profileURL = personData[Constants.profileURL];
      });
    }
  }
}
