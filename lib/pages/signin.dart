// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:dayflow/pages/homePage.dart';
import 'package:dayflow/pages/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/components/my_text_field.dart';
import 'package:dayflow/components/sign_in_button.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => homePage(
                  onTap: () {},
                )),
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
                    ),
                  ),
                ),
                //tagline
                SizedBox(
                  height: 25,
                ),
                //username
                MyTextField(
                  controller: emailController,
                  placeholder: 'E-Mail',
                  obscuretext: false,
                ),
                SizedBox(height: 25),

                //password
                MyTextField(
                  controller: passwordController,
                  placeholder: 'Password',
                  obscuretext: true,
                ),

                SizedBox(height: 25),
                //forgot password
                Text('forgot password'),

                //sign in button
                SizedBox(height: 25),
                ShadButton(
                  onPressed:
                      signUserIn, // Call the signUserIn function directly
                  text: const Text('Sign in'),
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
