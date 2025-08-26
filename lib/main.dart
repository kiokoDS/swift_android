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
    getToken().then((token) async {
      authenticated = token != null;
    });
    return FutureBuilder(
      future: getToken(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MaterialApp(
            home: snapshot.data != null ? Indexpage() : LoginScreen(),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
