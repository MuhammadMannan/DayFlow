import 'package:dayflow/pages/homePage.dart';
import 'package:dayflow/pages/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../components/addTaskModal.dart';

class taskPage extends StatefulWidget {
  taskPage({Key? key, required Null Function() onTap});

  @override
  State<taskPage> createState() => _taskPageState();
}

class _taskPageState extends State<taskPage> {
  int _selectedIndex = 2;
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Tasks',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF234EF3)),
                      ),
                      Text(
                        'Tuesday July 18',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Gap(12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFFD5E8FA),
                      foregroundColor: Colors.blue.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => showModalBottomSheet(
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      context: context,
                      builder: (context) => addTaskModal(),
                    ),
                    child: const Text(
                      'Add Task',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                tabBorderRadius: 5,
                tabBackgroundColor: const Color(0xFFA5B7FF),
                backgroundColor: const Color(0xFF234EF3),
                color: const Color(0xFFA5B7FF),
                activeColor: Colors.white,
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
                    // Navigate to the Dashboard page (replace Placeholder() with your actual page)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => homePage(
                          onTap: () {},
                        ),
                      ),
                    );
                  } else if (index == 2) {
                    // Do nothing as we are already on the taskPage
                  }
                },
                tabs: [
                  const GButton(
                    icon: Icons.book_rounded,
                    text: 'Entries',
                  ),
                  const GButton(
                    icon: Icons.dashboard_rounded,
                    text: 'Dashboard',
                  ),
                  const GButton(
                    icon: Icons.task_alt_rounded,
                    text: 'Tasks',
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
