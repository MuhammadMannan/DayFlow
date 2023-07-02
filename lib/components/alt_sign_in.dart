import 'package:flutter/material.dart';

class AltSignInButton extends StatelessWidget {
  const AltSignInButton(
      {super.key,
      required this.signInLable,
      required this.signinIcon,
      required this.buttonColor,
      required this.textColor});

  final String signInLable;
  final Icon signinIcon;
  final Color buttonColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: buttonColor, borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            signinIcon,
            SizedBox(
              width: 10,
            ),
            Text(
              signInLable,
              style: TextStyle(color: textColor),
            )
          ],
        ),
      ),
    );
  }
}
