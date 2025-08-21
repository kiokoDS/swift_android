import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/index.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final EmailController = TextEditingController();
  final PasswordController = TextEditingController();

  bool _isLoading = false;

  final dio = Dio();

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    await prefs.setString("token", token);
    await prefs.setString("username", decodedToken["username"]);
    await prefs.setString("phone", decodedToken["phone"]);
    await prefs.setString("user_id", decodedToken["user_id"].toString());
  }

  Future<void> sendLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await dio.post(
        "https://3ccb08a66ef8.ngrok-free.app/login",
        data: {
          "username": EmailController.text,
          "password": PasswordController.text,
        },
      );
      final token = response.data["token"]; // Already parsed JSON
      await saveToken(token);
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Indexpage()),
      );
    } catch (e) {
      print("Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Stack(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/images/logo.png",
                  fit: BoxFit.contain,
                  height: 150,
                ),
              ],
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Bonjour!",
                      style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.w800,
                        fontSize: 25,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        "log in with your swift account to get things started",
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: FontWeight.w300,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Container(
                        height: 50,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // background color
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // makes it rounded
                        ),
                        child: TextField(
                          controller: EmailController,
                          style: GoogleFonts.hindSiliguri(),
                          decoration: InputDecoration(
                            hintText: "Enter your email",
                            border: InputBorder
                                .none, // remove default TextField border
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Container(
                        height: 50,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // background color
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // makes it rounded
                        ),
                        child: TextField(
                          controller: PasswordController,
                          textAlignVertical: TextAlignVertical.center,
                          style: GoogleFonts.hindSiliguri(),
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            border: InputBorder
                                .none, // remove default TextField border
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.orange[700],
                          ),
                          onPressed: () {
                            sendLogin();
                          },
                          child: _isLoading
                              ? LoadingIndicator(
                                  indicatorType: Indicator.ballSpinFadeLoader,
                                  colors: const [Colors.white],
                                  strokeWidth: 2,
                                )
                              : Text(
                                  "Log In",
                                  style: GoogleFonts.hindSiliguri(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
