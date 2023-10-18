// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class TaskGraph extends StatelessWidget {
  TaskGraph({
    super.key,
    required this.userEmail,
  });

  final String userEmail;

  List<Color> gradientColors = [
    Colors.blue,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          return const CircularProgressIndicator();
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

        return Column(
          children: [
            const Text(
              'Monitor Your Progress',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF234EF3)),
            ),
            const Gap(12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.20,
              width: MediaQuery.of(context).size.width * 0.85,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF234EF3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
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
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: bottomTitleWidgets,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                              interval: 1.5,
                              getTitlesWidget: leftTitleWidgets,
                              //reservedSize: 42,
                            ),
                          ),
                        ),
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
                              gradient: LinearGradient(
                                colors: gradientColors
                                    .map((color) => color.withOpacity(.3))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white);

    // Get the current day of the week
    final currentDay = DateTime.now().weekday;

    // List of day names
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate the index for the current day
    final startIndex = (currentDay + value).toInt() % 7;

    // Exclude the first and last day labels
    if (value == -.5 || value == 6.5) {
      return Container();
    }

    return Transform.rotate(
      angle: 0,
      child: SideTitleWidget(
        axisSide: meta.axisSide,
        child: Column(
          children: [
            Gap(5),
            Text(dayNames[startIndex], style: style),
          ],
        ),
      ),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white);

    String text = '${value.toInt()}';

    return Text(
      text,
      style: style,
      //textAlign: TextAlign.right,
    );
  }
}
