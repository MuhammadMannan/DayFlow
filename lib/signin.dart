// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'components/my_text_field.dart';
import 'components/sign_in_button.dart';
import 'components/alt_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

class signin extends StatelessWidget {
  signin({super.key});

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

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
            child: Column(
              children: [
                Text('DayFlow',
                    style: GoogleFonts.poppins(
                        fontStyle: FontStyle.normal,
                        fontSize: 70,
                        color: Color(0xFF234EF3))),
                //logo/title
                Padding(
                  padding:
                      const EdgeInsets.only(left: 24, right: 24, bottom: 25),
                  child: Text(
                    'Welcome back! \We missed you! 👋',
                    style: TextStyle(
                        fontSize: 38,
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
                  controller: usernameController,
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
                MySignInButton(onTap: signUserIn()),

                //sign in
                //google + apple
                SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'or continue with',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //google sign in
                      const AltSignInButton(
                        signInLable: 'Sign in with Google',
                        signinIcon: Icon(
                          Icons.android,
                          color: Colors.lightGreen,
                        ),
                        textColor: Colors.white,
                        buttonColor: Colors.lightBlue,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      //apple sign in
                      const AltSignInButton(
                        signInLable: 'Sign in with Apple',
                        signinIcon: Icon(
                          Icons.apple,
                          color: Colors.white,
                        ),
                        buttonColor: Colors.black,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 25,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Not a member? '),
                    Text(
                      'Register Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
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
    );
  }

  signUserIn() {}
}
