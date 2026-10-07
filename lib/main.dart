import 'package:digital_khata/app.dart';
import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.initialize();
  await AuthService.instance.restoreSession();
  runApp(const MyApp());
}
