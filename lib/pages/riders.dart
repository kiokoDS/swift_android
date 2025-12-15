import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class Riders extends StatefulWidget {
  @override
  State<Riders> createState() => _RidersPageState();
}

class _RidersPageState extends State<Riders> {
  final Dio dio = Dio();

  List<dynamic> orders = [];
  bool isLoading = true;

  var userid = "";
  var token = "";


  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userid = prefs.getString("user_id")!;
      token = prefs.getString("token")!;
    });
    return prefs.getString("token");
  }

  //pagination
  int page = 0;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchOrders();
    getToken();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      fetchOrders();
    }
  }

  Future<void> fetchOrders() async {
    var key = await getToken();
    var headers = {'Authorization': 'Bearer $key'};

    try {
      var response = await dio.request(
        'https://www.swiftnet.site/backend/api/drivers/assigned-to-me?page=${page}',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        setState(() {
          orders = response.data["items"] ?? response.data;
          isLoading = false;
          page++;
          hasMore = !response.data["last"];
        });
      } else {
        print("Error: ${response.statusMessage}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Exception: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Riders",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : orders.isEmpty
          ? Center(
              child: Text(
                "No riders found",
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                var ff = DateTime.tryParse(order["lastOrderAt"]);

                return RiderCard(
                  name: order["username"] ?? "N/A",
                  licensePlate: order["licensePlate"] ?? "N/A",
                  rating: order["rating"] ?? "N/A",
                  createdAt: ff,
                  norides: order["ridesWithYou"].toString() ?? "N/A",
                  riderid: order["user_id"].toString(),
                  userid: userid.toString(),
                  token: token,
                );
              },
            ),
    );
  }
}

class RiderCard extends StatelessWidget {
  final String name;
  final String licensePlate;
  final int rating;
  final DateTime? createdAt;
  final String norides;
  final String riderid;
  final String userid;
  final String token;

  const RiderCard({
    super.key,
    required this.name,
    required this.licensePlate,
    required this.rating,
    this.createdAt,
    required this.norides,
    required this.riderid,
    required this.userid,
    required this.token
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: EdgeInsetsGeometry.all(10),
            child: Image.asset(
              "assets/images/rider.png",
              fit: BoxFit.contain,
              height: 40,
              width: 40,
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Plates: " + licensePlate,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "No of rides: " + norides,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            buildRating2(rating.toDouble(), userid, riderid, token),
          ],
        ),
        trailing: IconButton(
          onPressed: () {},
          icon: Icon(Icons.call, color: Colors.deepOrange),
        ),
      ),
    );
  }
}

Widget buildRating(
  double rating, {
  double size = 15,
  Color color = Colors.amber,
      required String riderid,
      required String userid
}) {
  // Clamp rating between 0 and 5 just in case
  rating = rating.clamp(0, 5);

  List<Widget> stars = [];

  for (int i = 1; i <= 5; i++) {
    if (i <= rating) {
      stars.add(Icon(Icons.star, color: color, size: size));
    } else if (i - rating <= 0.5) {
      stars.add(Icon(Icons.star_half, color: color, size: size));
    } else {
      stars.add(Icon(Icons.star_border, color: color, size: size));
    }
  }

  return Row(mainAxisSize: MainAxisSize.min, children: stars);
}

Widget buildRating2(double rating, String userid, String riderid, String key) {

  Future <void> updateRating(int ratings) async{
    print(ratings);
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': "Bearer ${key}"
    };
    var data = json.encode({
      "rating": ratings,
      "ratingby": userid,
      "user_id": riderid
    });
    var dio = Dio();
    var response = await dio.request(
      'https://www.swiftnet.site/backend/api/user/rating',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
    }
    else {
      print(response.statusMessage);
    }
  }


  return RatingBar.builder(
    itemSize: 15,
    initialRating: rating,
    minRating: 0,
    direction: Axis.horizontal,
    allowHalfRating: false,
    itemCount: 5,
    itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
    onRatingUpdate: (rating) {
      updateRating(rating.round());
    },
  );
}
