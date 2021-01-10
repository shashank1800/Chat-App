import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './LoginData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './Home.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class PhoneVerfy extends StatefulWidget {
  @override
  _PhoneVerfyState createState() => _PhoneVerfyState();
}

class _PhoneVerfyState extends State<PhoneVerfy> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();

  String _verificationId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
              child: RaisedButton(
                onPressed: () async {
                  _verifyPhoneNumber();
                },
                child: const Text('Verify phone number'),
              ),
            ),
            TextField(
              controller: _smsController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Verification code'),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
              child: RaisedButton(
                onPressed: () async {
                  _signInWithPhoneNumber();
                },
                child: const Text('Sign in with phone number'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyPhoneNumber() async {
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      _auth.signInWithCredential(phoneAuthCredential);

      checkUserExists();
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      print("PhoneVerificationFailed");
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      _verificationId = verificationId;
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      print(PhoneCodeAutoRetrievalTimeout);
    };

    await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumberController.text,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  void _signInWithPhoneNumber() async {
    final AuthCredential credential = PhoneAuthProvider.getCredential(
      verificationId: _verificationId,
      smsCode: _smsController.text,
    );
    await _auth.signInWithCredential(credential).then((respo) {
      if (respo.user != null) checkUserExists();
    });
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
    }
  }

  Future<bool> checkDataExist(var user) async {
    var response = user.phoneNumber;
    var documentRef = Firestore.instance.collection("User").document(response);
    var data = await documentRef.get();
    return (data.exists) ? true : false;
  }
}
