import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MatchPage extends StatefulWidget {
  final String message;
  const MatchPage({Key? key, required this.message}) : super(key: key);

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  var token = "";

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString("token")!;
    });
    return prefs.getString("token");
  }

  Future<void> match() async {
    var key = await getToken();
    var headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer ${key}',
    };
    var data = {'orderId': widget.message};
    var dio = Dio();
    var response = await dio.request(
      'http://209.126.8.100:4141/api/orders/match-driver',
      options: Options(method: 'POST', headers: headers),
      data: data,
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          action: SnackBarAction(
            textColor: Colors.white,
            label: "OK",
            onPressed: () =>
                ScaffoldMessenger.of(context).removeCurrentSnackBar(),
          ),
          backgroundColor: Colors.green,
          content: ListTile(
            leading: Icon(Icons.check_circle, color: Colors.white),
            title: Text("Rider found"),
            subtitle: Text(
              "${response.data["licensePlate"]} will be there shortly",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } else {
      print(response.statusMessage);
    }
  }

  @override
  void initState() {
    super.initState();
    match();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/meditate.png",
              fit: BoxFit.contain,
              height: 150,
            ),
            SizedBox(
              height: 20,
              child: LoadingIndicator(
                indicatorType: Indicator.ballPulseSync,
                colors: const [Colors.deepOrange],
                strokeWidth: 2,
              ),
            ),
            Text(
              "Matching you with a rider",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
