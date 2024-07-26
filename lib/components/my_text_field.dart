// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MyTextField extends StatelessWidget {
  const MyTextField({
    super.key,
    this.controller,
    required this.placeholder,
    required this.obscuretext,
  });

  final controller;
  final String placeholder;
  final bool obscuretext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ShadInput(
        controller: controller,
        placeholder: Text(placeholder),
        obscureText: obscuretext,
      ),
    );
  }
}
