// ignore_for_file: prefer_const_constructors
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final user = FirebaseAuth.instance.currentUser!;

  //function to sign out user
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/Group2.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'DayFlow',
              style: TextStyle(
                color: Color(0xFF234EF3),
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
                  onPressed: signUserOut,
                  icon: Icon(
                    Icons.logout,
                    color: Color(0xFF234EF3),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //welcome text
                Padding(
                  padding: const EdgeInsets.only(left: 34.0, top: 20),
                  child: Text(
                    'Welcome back!',
                    style: GoogleFonts.poppins(
                        fontSize: 30, fontWeight: FontWeight.w600),
                  ),
                ),
                //Overview Panel
                Padding(
                  padding: const EdgeInsets.only(left: 34.0, top: 20),
                  child: Text(
                    'Your Streak',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                //streaks will go in here
                Padding(
                  padding: const EdgeInsets.only(left: 34.0, top: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: SizedBox(
                      width: 300,
                      height: 100,
                    ),
                  ),
                ),
                //option to create a new entry
                Padding(
                  padding: const EdgeInsets.only(left: 34.0, top: 20),
                  child: Text(
                    'Your Days',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
