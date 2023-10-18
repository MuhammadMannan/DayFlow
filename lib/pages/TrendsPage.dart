// library_private_types_in_public_api
// ignore_for_file: file_names
import 'package:dayflow/pages/homePage.dart';
import 'package:dayflow/pages/signin.dart';
import 'package:dayflow/pages/taskPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../components/TaskGraph.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  _TrendsPageState createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser!;
  late String userEmail;

  @override
  void initState() {
    super.initState();
    getUserEmail();
  }

  void getUserEmail() async {
    if (user.email != null) {
      setState(() {
        userEmail = user.email!;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Column(
        children: [
          Center(
            child: TaskGraph(userEmail: userEmail),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 15),
        child: FractionallySizedBox(
          widthFactor: 0.85,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF234EF3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GNav(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                tabBorderRadius: 5,
                backgroundColor: const Color(0xFF234EF3),
                color: Colors.white,
                activeColor: const Color(0xFFA5B7FF),
                gap: 8,
                iconSize: 20,
                textSize: 10,
                padding: const EdgeInsets.all(6),
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });

                  // Switch between pages based on the selected tab index
                  if (index == 0) {
                    // Navigate to the Entries page (replace Placeholder() with your actual page)
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => YourEntriesPage()));
                  } else if (index == 1) {
                    // Already on TrendsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => homePage(onTap: () {}),
                      ),
                    );
                  } else if (index == 2) {
                    // Navigate to the Tasks page (replace taskPage() with your actual page)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => taskPage(onTap: () {}),
                      ),
                    );
                  }
                },
                tabs: const [
                  GButton(
                    icon: Icons.area_chart,
                    //text: 'Entries',
                  ),
                  GButton(
                    icon: (Icons.dashboard_rounded),
                    //text: 'Dashboard',
                  ),
                  GButton(
                    icon: Icons.task_alt_rounded,
                    //text: 'Tasks',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
