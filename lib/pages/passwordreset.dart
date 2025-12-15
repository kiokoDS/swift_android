import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/homepage.dart';

class PasswordReset extends StatefulWidget {
  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final EmailController = TextEditingController();
  final OtpController = TextEditingController();
  final NewPasswordController = TextEditingController();
  final ConfirmationController = TextEditingController();

  var _isLoading = false;
  var _sendingOtp = false;
  var email = "";

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString("email")!;
    });
    return prefs.getString("token");
  }

  Future<void> sendOtp() async {
    setState(() {
      _sendingOtp = true;
    });

    var key = await getToken();
    var headers = {'Authorization': "Bearer ${key}"};
    var data = FormData.fromMap({'email': email});

    var dio = Dio();
    var response = await dio.request(
      'https://www.swiftnet.site/backend/forgot-password/request',
      options: Options(method: 'POST', headers: headers),
      data: data,
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
      setState(() {
        _sendingOtp = false;
      });
    } else {
      print(response.statusMessage);
      setState(() {
        _sendingOtp = false;
      });
    }
  }

  Future<void> resetPassword() async {
    setState(() {
      _isLoading = true;
    });
    var key = await getToken();
    var headers = {
      'Authorization': "Bearer ${key}"
    };
    var data = FormData.fromMap({
      'email': email,
      'otp': OtpController.text,
      'new_password': NewPasswordController.text
    });

    var dio = Dio();
    var response = await dio.request(
      'https://www.swiftnet.site/backend/forgot-password/reset',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
      setState(() {
        _isLoading = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Password successfully saved"),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Homepage(),
        ),
      );
    }
    else {
      print(response.statusMessage);
      setState(() {
        _isLoading = true;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Password Reset",
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            Padding(
              padding: EdgeInsets.only(top: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Otp",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  _sendingOtp
                      ? SizedBox(
                          height: 20,
                          child: LoadingIndicator(
                            indicatorType: Indicator.ballPulseSync,
                            colors: const [Colors.deepOrange],
                            strokeWidth: 2,
                          ),
                        )
                      : TextButton(
                          onPressed: () {
                            sendOtp();
                          },
                          child: Text(
                            "send otp?",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 0),
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200], // background color
                  borderRadius: BorderRadius.circular(10), // makes it rounded
                ),
                child: TextField(
                  controller: OtpController,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Otp",
                    border: InputBorder.none, // remove default TextField border
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200], // background color
                  borderRadius: BorderRadius.circular(10), // makes it rounded
                ),
                child: TextField(
                  controller: NewPasswordController,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: InputBorder.none, // remove default TextField border
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Container(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.deepOrange[700],
                  ),
                  onPressed: () {},
                  child: _isLoading
                      ? LoadingIndicator(
                          indicatorType: Indicator.ballPulseSync,
                          colors: const [Colors.white],
                          strokeWidth: 2,
                        )
                      : Text(
                          "Log In",
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
    );
  }
}
