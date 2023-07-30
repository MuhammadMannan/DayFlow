// ignore_for_file: sort_child_properties_last, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:dayflow/pages/signin.dart';
import 'package:dayflow/pages/taskPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../components/dateTile.dart';
import '../components/taskTile.dart';

class homePage extends StatelessWidget {
  const homePage({super.key});

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
      backgroundColor: const Color(0xFFEDF3FC),
      appBar: AppBar(
        title: const Text(
          'DayFlow',
          style: TextStyle(
            color: Color(0xFF234EF3),
            fontWeight: FontWeight.w600,
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
            icon: const Icon(
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
              icon: const Icon(
                Icons.logout,
                color: Color(0xFF234EF3),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => taskPage(
                          onTap: () {},
                        ),
                      ),
                    );
                  },
                  child: taskTile(),
                ),

                //date container
                dateTile()
              ],
            ),
          ],
        ),
      ),
    );
  }
}
