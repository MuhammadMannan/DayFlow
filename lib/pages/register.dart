// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:dayflow/pages/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/components/my_text_field.dart';
import 'package:dayflow/components/sign_in_button.dart';
import 'package:google_fonts/google_fonts.dart';

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
      //check is password and confirm password is the same
      if (passwordController.text == confirmPasswordController.text) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      } else {
        //show error message, passwords do not match
        showErrorMessage('Passwords do not match!');
      }

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showErrorMessage(e.code);
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
                    'Hi nice to meet you! 👋',
                    style: GoogleFonts.poppins(
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
                          color: Colors.blue[700],
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
