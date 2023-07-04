import 'package:dayflow/pages/register.dart';
import 'package:dayflow/pages/signin.dart';
import 'package:flutter/material.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  //initially show login page
  bool showLoginPage = true;

  //toggle between login and registerpage
  void togglePages() {
    setState(
      () {
        showLoginPage = !showLoginPage;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return signin(
        onTap: togglePages,
      );
    } else {
      return registerPage(
        onTap: togglePages,
      );
    }
  }
}
