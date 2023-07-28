// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:dayflow/pages/taskPage.dart';
import 'package:dayflow/pages/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/components/my_text_field.dart';
import 'package:dayflow/components/sign_in_button.dart';

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
    // Show a loading circle
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

      // Authentication successful, navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      // Authentication failed, show error message
      showErrorMessage(e.code);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDF3FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DayFlow',
                  style: TextStyle(
                    fontStyle: FontStyle.normal,
                    fontSize: 70,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF234EF3),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                //logo/title
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Text(
                    'Welcome back, we missed you! 👋',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF234EF3)),
                  ),
                ),
                //tagline
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
                  onTap: signUserIn, // Call the signUserIn function directly
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => registerPage(
                              onTap: () {},
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Register Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF234EF3),
                        ),
                      ),
                    ),
                  ],
                )

                //regster now
              ],
            ),
          ),
        ),
      ),
    );
  }
}
