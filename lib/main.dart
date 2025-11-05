import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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

    String ACCESS_TOKEN = String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(ACCESS_TOKEN);

    return FutureBuilder(
      future: getToken(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MaterialApp(
            home: snapshot.data != null ? Indexpage() : LoginScreen(),
          );
        } else {
          return MaterialApp(
            home: LoginScreen()
          );
        }
      },
    );
  }
}
