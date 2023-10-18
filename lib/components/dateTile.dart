import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class dateTile extends StatelessWidget {
  const dateTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat('d EEEE').format(currentDate);
    String formattedMonth = DateFormat('MMMM').format(currentDate);
    String formattedYear = DateFormat('y').format(currentDate);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      width: 160,
      height: 160,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF234EF3)),
                  ),
                  Text(
                    formattedMonth,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF234EF3)),
                  ),
                  Text(
                    formattedYear,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF234EF3)),
                  ),
                ],
              ),
            ),
            const Gap(10),
            Text(
              'No Entries Completed',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400),
            )
          ],
        ),
      ),
    );
  }
}
