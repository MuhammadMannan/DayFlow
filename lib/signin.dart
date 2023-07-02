import 'package:flutter/material.dart';
import 'components/my_text_field.dart';
import 'components/sign_in_button.dart';

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
                //logo/title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                  child: Text(
                    'Welcome back! \We missed you! 👋',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF234EF3)),
                  ),
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
