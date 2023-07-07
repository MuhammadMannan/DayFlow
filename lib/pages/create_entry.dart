// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:dayflow/pages/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class createEntry extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  //function to sign out user
  void signUserOut(BuildContext context) {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => signin(
            onTap: () {},
          ),
        ),
        (route) => false,
      );
    }).catchError((error) {
      // Handle sign out error
      print('Error signing out: $error');
    });
  }

  createEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDF3FC),
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: IconButton(
              onPressed: () {
                // Handle icon button tap
              },
              icon: Icon(
                Icons.menu,
                color: Color(0xFF234EF3),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: IconButton(
                onPressed: () => signUserOut(context), // Pass context here
                icon: Icon(
                  Icons.logout,
                  color: Color(0xFF234EF3),
                ),
              ),
            ),
          ]),
      body: SingleChildScrollView(),
    );
  }
}
