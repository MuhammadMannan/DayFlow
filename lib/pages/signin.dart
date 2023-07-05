// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/components/my_text_field.dart';
import 'package:dayflow/components/sign_in_button.dart';
import 'package:google_fonts/google_fonts.dart';

class signin extends StatefulWidget {
  final Function() onTap;

  signin({super.key, required this.onTap});

  @override
  State<signin> createState() => _signinState();
}

class _signinState extends State<signin> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  //error message to user
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(message),
          ),
        );
      },
    );
  }

  void signUserIn() async {
    //show a loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showErrorMessage(e.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/Group2.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DayFlow',
                    style: GoogleFonts.poppins(
                      fontStyle: FontStyle.normal,
                      fontSize: 70,
                      color: Color(0xFF234EF3),
                    ),
                  ),
                  //logo/title
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 24, right: 24, bottom: 25),
                    child: Text(
                      'Welcome back, we missed you! 👋',
                      style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF234EF3)),
                    ),
                  ),
                  //tagline
                  Text(
                    '"Believe You Can And You’re Halfway There\n– Theodore Roosevelt"',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  //username
                  MyTextField(
                    controller: emailController,
                    hintText: 'E-Mail',
                    obscureText: false,
                  ),
                  SizedBox(height: 25),

                  //password
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),

                  SizedBox(height: 25),
                  //forgot password
                  Text('forgot password'),

                  //sign in button
                  SizedBox(height: 25),
                  MySignInButton(
                    onTap: signUserIn,
                    text: 'Sign in',
                  ),

                  //sign in
                  //google + apple
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Not a member? '),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          'Register Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      )
                    ],
                  )

                  //regster now
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
