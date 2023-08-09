// library_private_types_in_public_api

import 'dart:ui';
import 'package:dayflow/pages/homePage.dart';
import 'package:dayflow/pages/signin.dart';
import 'package:dayflow/pages/taskPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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

  final List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

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
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            widthFactor: 0.9, // Adjust the width factor as needed
            heightFactor: 0.3, // Adjust the height factor as needed
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userEmail)
                  .collection('tasks')
                  .where('createdAt',
                      isGreaterThanOrEqualTo:
                          DateTime.now().subtract(const Duration(days: 7)))
                  .where('isComplete', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final taskDocs = snapshot.data!.docs;
                final dailyCompletedTasks = List<int>.filled(7, 0);

                for (var doc in taskDocs) {
                  DateTime createdAt = doc['createdAt'].toDate();
                  int dayIndex = DateTime.now().difference(createdAt).inDays;
                  if (dayIndex < 7) {
                    dailyCompletedTasks[6 - dayIndex]++;
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF234EF3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 12),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (value) {
                            return const FlLine(
                                color: Colors.white30,
                                strokeWidth: 0.5); // Add the semicolon here
                          },
                          getDrawingVerticalLine: (value) {
                            return const FlLine(
                                color: Colors.white30,
                                strokeWidth: 0.5); // Add the semicolon here
                          },
                        ),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: -0.5,
                        maxX: 6.5,
                        minY: 0,
                        maxY: (dailyCompletedTasks)
                                .reduce(
                                    (max, value) => max > value ? max : value)
                                .toDouble() +
                            2,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              7,
                              (index) => FlSpot(
                                index.toDouble(),
                                dailyCompletedTasks[index].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            barWidth: 3,
                            color: Colors.white,
                            isStrokeCapRound: false,
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
