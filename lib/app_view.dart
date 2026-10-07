import 'package:digital_khata/controller/auth.dart';
import 'package:digital_khata/controller/toggle_login_signup.dart';
import 'package:digital_khata/screens/content/home/home_screen.dart';
import 'package:digital_khata/screens/content/people/list_people_screen.dart';
import 'package:flutter/material.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Pak Khata",
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          surface: Colors.grey.shade100,
          onSurface: Colors.black,
          primary: const Color(0xFF087F5B),
          secondary: const Color(0xFF20A779),
          tertiary: const Color(0xFF72C79E),
          outline: Colors.grey,
        ),
      ),

      home: AuthController(),
      routes: {
        '/toggle_login_signup_screen': (context) => const ToggleLoginSignup(),
        '/home_screen': (context) => HomeScreen(),
        // '/profile_page': (context) => ProfilePage(),
        '/list_people_screen': (context) => ListPeopleScreen(),
      },
    );
  }
}
