import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/index.dart';
import 'pages/login.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  @override
  Widget build(BuildContext context) {
    var authenticated = false;
    getToken().then((token) {
      if (token != null) {
        authenticated = true;
      }
    });
    return MaterialApp(home: authenticated ? Indexpage() : LoginScreen());
  }
}
