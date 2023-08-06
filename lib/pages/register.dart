// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, depend_on_referenced_packages
import 'package:dayflow/pages/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/components/my_text_field.dart';
import 'package:dayflow/components/sign_in_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class registerPage extends StatefulWidget {
  final Function() onTap;

  registerPage({super.key, required this.onTap});

  @override
  State<registerPage> createState() => _registerPageState();
}

class _registerPageState extends State<registerPage> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final confirmPasswordController = TextEditingController();

  CollectionReference users = FirebaseFirestore.instance.collection('users');

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

  void signUserUp() async {
    // Show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Checking if password is confirmed
      if (passwordController.text == confirmPasswordController.text) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Adding user details
        await addUserDetails(
            emailController.text.trim()); // Trim the email here

        // Pop the loading circle
        Navigator.pop(context);

        // Show "Welcome to DayFlow" message
        final snackBar = SnackBar(
          content: Text('Welcome to DayFlow'),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // Delay the navigation to the sign-in page
        Future.delayed(Duration(seconds: 2), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => signin(
                onTap: () {},
              ),
            ),
          );
        });
      } else {
        // Show error message, passwords don't match
        showErrorMessage("Passwords don't match");
        // Pop the loading circle
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // Pop loading circle
      Navigator.pop(context);

      if (e.code == 'invalid-email' || e.code == 'user-not-found') {
        // Show error to user
        showErrorMessage("Incorrect Email");
      } else if (e.code == 'wrong-password') {
        // Show error to user
        showErrorMessage("Incorrect Password");
      }
    }
  }

  // void signUserUp() async {
  //   print("signing in with firebase");
  //   // show loading circle
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return const Center(
  //         child: CircularProgressIndicator(),
  //       );
  //     },
  //   );

  //   // try creating user
  //   try {
  //     //checking if password is confirmed
  //     if (passwordController.text == confirmPasswordController.text) {
  //       await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //         email: emailController.text,
  //         password: passwordController.text,
  //       );

  //       // adding user details
  //       addUserDetails(emailController.text.trim()); // Trim the email here
  //     } else {
  //       // show error message, passwords don't match
  //       showErrorMessage("Passwords don't match");
  //     }

  //     // pop the loading circle
  //     Navigator.pop(context);
  //   } on FirebaseAuthException catch (e) {
  //     // pop loading circle
  //     Navigator.pop(context);
  //     // wrong email
  //     if (e.code == 'invalid-email' || e.code == 'user-not-found') {
  //       //show error to user
  //       showErrorMessage("Incorrect Email");
  //     }

  //     // wrong password
  //     else if (e.code == 'wrong-password') {
  //       // show error to user
  //       showErrorMessage("Incorrect Password");
  //     }
  //   }
  // }

  Future<void> addUserDetails(String email) async {
    return users
        .doc(email)
        .set({'email': email})
        .then((value) => print("User Added"))
        .catchError((error) => print("Failed to add user: $error"));
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
                    fontWeight: FontWeight.bold,
                    fontSize: 70,
                    color: Color(0xFF234EF3),
                  ),
                ),
                //logo/title
                Padding(
                  padding:
                      const EdgeInsets.only(left: 24, right: 24, bottom: 25),
                  child: Text(
                    'Hi nice to meet you! 👋',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF234EF3)),
                  ),
                ),
                //tagline

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

                //confirm password
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm password',
                  obscureText: true,
                ),

                //sign in button
                SizedBox(height: 25),
                MySignInButton(
                  onTap: signUserUp,
                  text: 'Sign up',
                ),

                //sign in
                //google + apple
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => signin(
                              onTap: () {},
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Login Now',
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
