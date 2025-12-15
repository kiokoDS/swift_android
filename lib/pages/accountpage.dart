import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:swift/pages/login.dart';
import 'package:swift/pages/passwordreset.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  @override
  State<AccountPage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<AccountPage> {

  var userid = "";
  var loading = false;
  var userrating = "";

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userid = prefs.getString("user_id")!;
    });
    return prefs.getString("token");
  }

  Future<void> saveRating(String rating) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("rating", rating);
  }


  Future<void> getUserRating() async {
    setState(() {
      loading = true;
    });
    var key = await getToken();
    var headers = {
      'Authorization': "Bearer ${key}"
    };
    var dio = Dio();
    var response = await dio.request(
      'https://www.swiftnet.site/backend/api/user/6/rating',
      options: Options(
        method: 'GET',
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));

      var rating = response.data["rating"];
      await saveRating(rating.toString());

      setState(() {
        loading = false;
        userrating = rating.toString();
      });
    }
    else {
      print(response.statusMessage);
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState(){
    super.initState();
    getUserRating();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          "Simon Kioko",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: loading? SizedBox(
                          height: 20,
                          child: LoadingIndicator(
                            indicatorType: Indicator.ballPulseSync,
                            colors: const [Colors.deepOrangeAccent],
                            strokeWidth: 2,
                          ),
                        ) : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              size: 15,
                              color: Colors.deepOrangeAccent,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                userrating,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              "rating",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Your details",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: EdgeInsetsGeometry.only(top: 20),
                      //   child: Container(
                      //     decoration: BoxDecoration(
                      //       border: Border(
                      //         bottom: BorderSide(color: Colors.grey, width: 1),
                      //       ),
                      //     ),
                      //     child: ListTile(
                      //       leading: Icon(FeatherIcons.user, size: 22),
                      //       trailing: Icon(Icons.arrow_forward_ios, size: 15),
                      //       title: Text(
                      //         "Personal Info",
                      //         style: GoogleFonts.inter(
                      //           fontSize: 14,
                      //           fontWeight: FontWeight.w400,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      Padding(
                        padding: EdgeInsetsGeometry.only(top: 0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey, width: 1),
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(FeatherIcons.shield, size: 22),
                            trailing: Icon(Icons.arrow_forward_ios, size: 15),
                            title: Text(
                              "Safety & Privacy",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.only(top: 0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey, width: 1),
                            ),
                          ),
                          child: GestureDetector(
                            onTap:  () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PasswordReset(),
                                ),
                              );
                            },
                            child: GestureDetector(
                              onTap: ()
                                async {
                                  final Uri url = Uri.parse('https://swiftnet.site');
                                  if (!await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                  )) {
                                throw Exception('Could not launch $url');
                                }

                              },
                              child: ListTile(
                                leading: Icon(FeatherIcons.lock, size: 22),
                                trailing: Icon(Icons.arrow_forward_ios, size: 15),
                                title: Text(
                                  "Login & Security",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Cridentials",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.only(top: 0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey, width: 1),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: Icon(FeatherIcons.logOut, size: 22),
                              trailing: Icon(Icons.arrow_forward_ios, size: 15),
                              title: Text(
                                "Logout",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: EdgeInsetsGeometry.only(top: 0),
                      //   child: Container(
                      //     decoration: BoxDecoration(
                      //       border: Border(
                      //         bottom: BorderSide(color: Colors.grey, width: 1),
                      //       ),
                      //     ),
                      //     child: ListTile(
                      //       leading: Icon(FeatherIcons.delete, size: 22),
                      //       trailing: Icon(Icons.arrow_forward_ios, size: 15),
                      //       title: Text(
                      //         "Delete Account",
                      //         style: GoogleFonts.inter(
                      //           fontSize: 14,
                      //           fontWeight: FontWeight.w400,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
