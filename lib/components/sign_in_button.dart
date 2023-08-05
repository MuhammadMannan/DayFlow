import 'package:flutter/material.dart';

class MySignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  MySignInButton({Key? key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF234EF3),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              // BoxShadow(
              //   color: Color(0xFF84B1F3), // Shadow color
              //   blurRadius: 27, // Blur radius
              //   spreadRadius: 0, // Spread radius
              //   offset: Offset(0, 0), // Offset in X and Y directions
              // ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                text,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
