import 'package:digital_khata/controller/toggle_login_signup.dart';
import 'package:digital_khata/screens/content/home/home_screen.dart';
import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

class AuthController extends StatelessWidget {
  const AuthController({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: AuthService.instance.currentUserNotifier,
      builder: (context, user, _) =>
          user == null ? const ToggleLoginSignup() : const HomeScreen(),
    );
  }
}
