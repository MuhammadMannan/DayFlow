// ignore_for_file: avoid_print, invalid_return_type_for_catch_error

import 'package:dayflow/components/radioWidget.dart';
import 'package:dayflow/components/sign_in_button.dart';
import 'package:dayflow/components/textHeadingStyle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class addTaskModal extends StatefulWidget {
  addTaskModal({
    super.key,
  });

  @override
  State<addTaskModal> createState() => _addTaskModalState();
}

class _addTaskModalState extends State<addTaskModal> {
  @override
  void initState() {
    super.initState();
    getUserEmailAndName();
  }

  String? selectedCategory;

  final taskName = TextEditingController();

  final taskDesc = TextEditingController();

  final user = FirebaseAuth.instance.currentUser!;

  String userEmail = "";

  String formatDate(DateTime date, String pattern) {
    return DateFormat(pattern).format(date);
  }

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  void getUserEmailAndName() async {
    // Check if the user is signed in and has an email
    if (user.email != null) {
      userEmail = user.email!;
    }
  }

  void closeAddTaskModal() {
    Navigator.pop(context); // Close the modal
  }

  Future<void> addTaskDetails(
      String taskName, String taskDesc, String category) async {
    // Add the new task as a new document in the 'tasks' collection
    return users.doc(userEmail).collection('tasks').add({
      'taskName': taskName,
      'taskDesc': taskDesc,
      'category': category,
      'isComplete': false, // Set isComplete to false by default
      'createdAt': FieldValue.serverTimestamp(),
    }).then((value) {
      // Close the modal after adding the task
    }).catchError((error) => print("Failed to add task: $error"));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFEDF3FC)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: double.infinity,
            child: Text(
              'Add A Task',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF234EF3)),
            ),
          ),
          const Gap(12),
          Divider(
            thickness: 1.2,
            color: Colors.blue.shade100,
          ),
          const Gap(12),
          const Text(
            'Task Name',
            style: textHeadingStyle.textStyle,
          ),
          const Gap(12),
          TextField(
            controller: taskName,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              hintText: 'Add a name for your task',
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Gap(12),
          const Text(
            'Description',
            style: textHeadingStyle.textStyle,
          ),
          const Gap(12),
          TextField(
            controller: taskDesc,
            maxLines: 3,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              hintText: 'Add a description for your task',
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Gap(12),
          const Text(
            'Category',
            style: textHeadingStyle.textStyle,
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: radioWidget(
                  categoryColor: Colors.red,
                  titleRadio: 'Work',
                  isSelected:
                      selectedCategory == 'Work', // Pass isSelected flag
                  onSelected: () {
                    setState(() {
                      selectedCategory = 'Work';
                    });
                  },
                ),
              ),
              Expanded(
                child: radioWidget(
                  categoryColor: Colors.blue,
                  titleRadio: 'School',
                  isSelected:
                      selectedCategory == 'School', // Pass isSelected flag
                  onSelected: () {
                    setState(() {
                      selectedCategory = 'School';
                    });
                  },
                ),
              ),
              Expanded(
                child: radioWidget(
                  categoryColor: Colors.green,
                  titleRadio: 'Person',
                  isSelected:
                      selectedCategory == 'Person', // Pass isSelected flag
                  onSelected: () {
                    setState(() {
                      selectedCategory = 'Person';
                    });
                  },
                ),
              ),
            ],
          ),
          const Gap(30),
          MySignInButton(
            onTap: () {
              addTaskDetails(
                taskName.text,
                taskDesc.text,
                selectedCategory!,
              );

              closeAddTaskModal(); // Close the modal after adding the task
            },
            text: 'Add Task',
          ),
        ],
      ),
    );
  }
}
