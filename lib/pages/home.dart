// ignore_for_file: prefer_const_constructors

import 'package:dayflow/pages/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_entry.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  List<String> tasks = []; // List to store tasks

  // Function to sign out user
  void signUserOut(BuildContext context) {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => signin(onTap: () {})),
        (route) => false,
      );
    }).catchError((error) {
      // Handle sign out error
      print('Error signing out: $error');
    });
  }

  // Function to add a task
  void addTask(String task) {
    setState(() {
      tasks.add(task);
    });
  }

  // Function to show dialog for adding a task
  void showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newTask = '';
        return AlertDialog(
          title: Text('Add Task'),
          content: TextField(
            onChanged: (value) {
              newTask = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter task',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                addTask(newTask);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
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
              onPressed: () => signUserOut(context),
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
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF234EF3),
                  ),
                ),
              ),

              // Panel to show tasks and add them
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Text(
                            'Today\'s Tasks',
                            style: GoogleFonts.poppins(fontSize: 30),
                          ),
                          SizedBox(height: 10),
                          FractionallySizedBox(
                            widthFactor: 0.9,
                            child: Container(
                              child: tasks.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(40.0),
                                        child: Text(
                                          'Add a task to get started',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: tasks.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return ListTile(
                                          title: Text(tasks[index]),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8.0, right: 8.0), // Add padding
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(
                                  0xFF234EF3), // Set the background color to blue
                              borderRadius: BorderRadius.circular(
                                  50), // Optional: Add border radius
                            ),
                            child: IconButton(
                              onPressed: showAddTaskDialog,
                              icon: Icon(
                                Icons.add,
                                size: 20,
                              ),
                              color: Colors
                                  .white, // Set the foreground (icon) color to white
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
