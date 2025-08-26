import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/index.dart';
import 'package:swift/pages/login.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<RegisterScreen> {
  final EmailController = TextEditingController();
  final PasswordController = TextEditingController();
  final phoneController = PhoneController();

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
        "http://209.126.8.100:4141/register",
        data: {
          "username": EmailController.text,
          "password": PasswordController.text,
          "phone": phoneController.value,
        },
      );
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
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
                      "Lets get started",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 25,
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
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Email",
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
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: PhoneFormField(
                          textAlign: TextAlign.center,
                          controller: phoneController,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Contact phone number",
                            //icon: Icon(FeatherIcons.phoneCall),
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
                          style: GoogleFonts.inter(fontSize: 14),
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
                            backgroundColor: Colors.deepOrange[700],
                          ),
                          onPressed: () {
                            sendLogin();
                          },
                          child: _isLoading
                              ? LoadingIndicator(
                                  indicatorType: Indicator.ballPulseSync,
                                  colors: const [Colors.white],
                                  strokeWidth: 2,
                                )
                              : Text(
                                  "Register",
                                  style: GoogleFonts.inter(
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
