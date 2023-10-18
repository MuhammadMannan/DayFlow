// ignore_for_file: invalid_return_type_for_catch_error, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dayflow/pages/TrendsPage.dart';
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
    DateTime today = DateTime.now();
    DateTime todayStart = DateTime(today.year, today.month, today.day);
    DateTime todayEnd = todayStart.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('tasks')
        .where('isComplete', isEqualTo: false)
        .where('createdAt', isGreaterThanOrEqualTo: todayStart)
        .where('createdAt', isLessThan: todayEnd)
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
      backgroundColor: const Color.fromARGB(255, 248, 249, 255),
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
                widthFactor: 0.85,
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
                              'Let\'s get stuff done',
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
                    const Gap(12),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: getTasksStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasData) {
                          final tasks = snapshot.data!.docs;
                          if (tasks.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [],
                              ),
                            );
                          } else {
                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: tasks.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final taskName = tasks[index]['taskName'];
                                final taskDesc = tasks[index]['taskDesc'];
                                final category = tasks[index]['category'];
                                final isComplete = tasks[index]['isComplete'];
                                final taskId =
                                    tasks[index].id; // Get the document ID

                                if (isComplete) {
                                  return const SizedBox.shrink();
                                }

                                // Define an Icon widget based on the category
                                Icon? categoryIcon;
                                if (category == 'School') {
                                  categoryIcon = const Icon(Icons.school,
                                      color: Colors.blue, size: 24);
                                } else if (category == 'Work') {
                                  categoryIcon = const Icon(Icons.work,
                                      color: Colors.blue, size: 24);
                                } else if (category == 'Person') {
                                  categoryIcon = const Icon(Icons.person,
                                      color: Colors.blue, size: 24);
                                }
                                return Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.15,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF234EF3),
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              bottomLeft: Radius.circular(16)),
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.045,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(taskName),
                                                subtitle: Text(taskDesc),
                                                trailing: Transform.scale(
                                                  scale: 1.5,
                                                  child: Checkbox(
                                                    activeColor:
                                                        const Color(0xFF234EF3),
                                                    shape: const CircleBorder(),
                                                    value:
                                                        isComplete, // Use the value from Firestore
                                                    onChanged: (value) async {
                                                      // Update the task's isComplete value to true
                                                      await updateTaskCompletionStatus(
                                                          taskId, true);
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Transform.translate(
                                                offset: const Offset(0, -12),
                                                child: Container(
                                                  child: Column(
                                                    children: [
                                                      Divider(
                                                        thickness: 1.5,
                                                        color: Colors
                                                            .grey.shade100,
                                                      ),
                                                      Row(
                                                        children: [
                                                          if (categoryIcon !=
                                                              null)
                                                            categoryIcon,
                                                          const SizedBox(
                                                              width:
                                                                  8), // Add spacing
                                                          Text(category),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        } else if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        } else {
                          return const CircularProgressIndicator();
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
              color: const Color(0xFF234EF3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GNav(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  if (index == 1) {
                    // Navigate to the Entries page (replace Placeholder() with your actual page)
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => YourEntriesPage()));
                  } else if (index == 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TrendsPage(),
                      ),
                    );
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
                tabs: const [
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
