import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/components/my_text_field.dart';
import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  final void Function()? onTap;
  final void Function()? onCustomerTap;

  const SignupScreen({
    super.key,
    required this.onTap,
    required this.onCustomerTap,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  //text controller
  final TextEditingController usernamecontroller = TextEditingController();

  final TextEditingController emailcontroller = TextEditingController();

  final TextEditingController passwordcontroller = TextEditingController();

  final TextEditingController confirmpasswordcontroller =
      TextEditingController();
  bool _loading = false;

  //register method
  Future<void> registerUser() async {
    if (passwordcontroller.text != confirmpasswordcontroller.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords don't match.")));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.signUp(name: usernamecontroller.text, email: emailcontroller.text, password: passwordcontroller.text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              //logo image
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/digital-khata-logo.png',
                  height: 100,
                  width: 100,
                ),

                //
                Text(
                  'Pak Khata',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w200),
                ),

                const SizedBox(height: 25),
                // text fields for username, email and password
                MyTextField(
                  hintText: "Username",
                  obscureText: false,
                  controller: usernamecontroller,
                ),
                const SizedBox(height: 15),
                MyTextField(
                  hintText: "Email",
                  obscureText: false,
                  controller: emailcontroller,
                ),

                const SizedBox(height: 15),
                MyTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: passwordcontroller,
                ),

                const SizedBox(height: 15),
                MyTextField(
                  hintText: "Confirm Password",
                  obscureText: true,
                  controller: confirmpasswordcontroller,
                ),

                SizedBox(height: 25),

                //sign in button
                _loading ? const CircularProgressIndicator() : MyButton(text: "Create account", onTap: registerUser),

                SizedBox(height: 15),

                //dont have an account? sign up
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            ' Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8), // spacing between the two lines
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Login as Customer',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onCustomerTap,
                          child: Text(
                            ' Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
