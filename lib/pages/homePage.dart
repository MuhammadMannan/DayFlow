// ignore_for_file: sort_child_properties_last, prefer_const_constructors, prefer_const_literals_to_create_immutables, file_names, camel_case_types, invalid_return_type_for_catch_error

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dayflow/pages/signin.dart';
import 'package:dayflow/pages/taskPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../components/addTaskModal.dart';
import '../components/dateTile.dart';
import '../components/taskTile.dart';

// ... (your existing imports)

class homePage extends StatefulWidget {
  const homePage({Key? key, required Null Function() onTap}) : super(key: key);

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  int _selectedIndex = 1;

  Stream<QuerySnapshot<Map<String, dynamic>>> getTasksStream() {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('tasks')
        .where('isComplete',
            isEqualTo: false) // Filter tasks with isComplete set to false
        .snapshots();
  }

  Future<void> updateTaskCompletionStatus(
      String taskId, bool isComplete) async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('tasks')
        .doc(taskId)
        .update({'isComplete': isComplete}).then((_) {
      print("Task completion status updated");
    }).catchError((error) => print("Failed to update task status: $error"));
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TaskTile(),
                  //date container
                  dateTile(),
                ],
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: Column(
                  children: [
                    Gap(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
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
                              'Let\'s get stuff done',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        Gap(12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0XFFD5E8FA),
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
                          child: Text(
                            'Add Task',
                          ),
                        ),
                      ],
                    ),
                    Gap(12),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: getTasksStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasData) {
                          final tasks = snapshot.data!.docs;
                          if (tasks.isEmpty) {
                            return Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Congrats you don't have any tasks for today!",
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                                Gap(35),
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 100,
                                  color: Colors.green,
                                )
                              ],
                            ));
                          } else {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final taskName = tasks[index]['taskName'];
                                final taskDesc = tasks[index]['taskDesc'];
                                final category = tasks[index]['category'];
                                final isComplete = tasks[index]['isComplete'];
                                final taskId =
                                    tasks[index].id; // Get the document ID

                                if (isComplete) {
                                  // Skip completed tasks
                                  return SizedBox.shrink();
                                }
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 6),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF234EF3), // Blue color
                                        Colors.white,
                                      ],
                                      stops: [
                                        0.05,
                                        0.02,
                                      ], // Adjust these values as needed
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      taskName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF234EF3),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          taskDesc,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (category == 'School')
                                              Icon(
                                                Icons.school,
                                                color: Colors.blue,
                                                size: 24,
                                              ),
                                            if (category == 'Work')
                                              Icon(
                                                Icons.work,
                                                color: Colors.blue,
                                                size: 24,
                                              ),
                                            if (category == 'Person')
                                              Icon(
                                                Icons.person,
                                                color: Colors.blue,
                                                size: 24,
                                              ),
                                            Spacer(), // Add spacer to create space between icons
                                            IconButton(
                                              icon: Icon(Icons.done),
                                              onPressed: () {
                                                // Update the task's isComplete value to true
                                                updateTaskCompletionStatus(
                                                    taskId, true);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // Implement a function to handle tile click
                                      // You can navigate to a task details page here
                                    },
                                  ),
                                );
                              },
                            );
                          }
                        } else if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        } else {
                          return CircularProgressIndicator();
                        }
                      },
                    ),
                    //card list of tasks
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      //navigation bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 15),
        child: FractionallySizedBox(
          widthFactor: 0.85,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color(0xFF234EF3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GNav(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                tabBorderRadius: 5,
                tabBackgroundColor: Color(0xFFA5B7FF),
                backgroundColor: Color(0xFF234EF3),
                color: Color(0xFFA5B7FF),
                activeColor: Colors.white,
                gap: 8,
                iconSize: 20,
                textSize: 10,
                padding: EdgeInsets.all(6),
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
                tabs: [
                  GButton(
                    icon: Icons.book_rounded,
                    //text: 'Entries',
                  ),
                  GButton(
                    icon: Icons.dashboard_rounded,
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
