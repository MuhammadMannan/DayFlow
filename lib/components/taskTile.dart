import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskTile extends StatefulWidget {
  @override
  _TaskTileState createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
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

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();
    DateTime todayStart = DateTime(today.year, today.month, today.day);
    DateTime todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('tasks')
          .where('createdAt', isGreaterThanOrEqualTo: todayStart)
          .where('createdAt', isLessThan: todayEnd)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('no tasks');
        }

        final tasks = snapshot.data!.docs;

        if (tasks.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF234EF3),
              borderRadius: BorderRadius.circular(16),
            ),
            width: 160,
            height: 160,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'No tasks\nfor today',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25),
                    textAlign: TextAlign.center,
                  ),
                  Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 45,
                  )
                ],
              ),
            ),
          );
        }

        final completedTasks =
            tasks.where((doc) => doc['isComplete'] == true).toList().length;

        final totalTasks = tasks.length;

        // Calculate the completion percentage
        double completionPercentage =
            totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;

        int completionAmount =
            ((completedTasks / totalTasks) * 100).round().toInt();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF234EF3),
            borderRadius: BorderRadius.circular(16),
          ),
          width: 160,
          height: 160,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text(
                  'Completed Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completionAmount%', // Show completed tasks out of total
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.75,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        10), // Adjust the radius as needed
                    child: LinearProgressIndicator(
                      value: completionPercentage / 100,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF95ABFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
