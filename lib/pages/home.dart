// ignore_for_file: prefer_const_constructors

import 'package:dayflow/pages/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_entry.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key});

  final user = FirebaseAuth.instance.currentUser;

  //function to sign out user
  void signUserOut(BuildContext context) {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => signin(
                  onTap: () {},
                )),
        (route) => false,
      );
    }).catchError((error) {
      // Handle sign out error
      print('Error signing out: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDF3FC),
      appBar: AppBar(
        title: Text(
          'DayFlow',
          style: GoogleFonts.robotoMono(
            textStyle: TextStyle(
              color: Color(0xFF234EF3),
            ),
          ),
        ),
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
        ],
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //welcome text
              Padding(
                padding: const EdgeInsets.only(left: 34.0, top: 20),
                child: Text(
                  'Welcome back!',
                  style: GoogleFonts.robotoMono(
                      fontSize: 30, fontWeight: FontWeight.w600),
                ),
              ),
              //Overview Panel
              Padding(
                padding: const EdgeInsets.only(left: 34.0, top: 20),
                child: Text(
                  'Your Tasks For Today',
                  style: GoogleFonts.robotoMono(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),

              //add tasks here

              Padding(
                padding: const EdgeInsets.only(left: 34.0, top: 20),
                child: Text(
                  'Previous Entries',
                  style: GoogleFonts.robotoMono(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),

              //adding entry
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => createEntry()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF234EF3),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
