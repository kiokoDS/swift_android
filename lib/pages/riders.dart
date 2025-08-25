import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Riders extends StatefulWidget {
  @override
  State<Riders> createState() => _RidersPageState();
}

class _RidersPageState extends State<Riders> {
  final Dio dio = Dio();
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    var headers = {
      'Authorization':
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6IiIsImV4cCI6MTc1NjExNjgxMywicGhvbmUiOiIwNzc3Nzc3Nzc3Iiwicm9sZV9pZCI6MiwidXNlcl9pZCI6MiwidXNlcm5hbWUiOiJkZmQifQ.t5tRCkVnhWUB4yq0HvSkAcB29B_2w3HCzDpvx_OExA0',
    };

    try {
      var response = await dio.request(
        'http://209.126.8.100:4141/api/drivers/all?page=0',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        setState(() {
          orders =
              response.data["items"] ??
              response.data; // Adjust depending on API structure
          isLoading = false;
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
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
            color: Colors.deepOrange,
          ))
          : orders.isEmpty
          ? Center(child: Text("No history found"))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 10),
                      child: Text(
                        "${order["orderId"] ?? "N/A"}",
                        style: GoogleFonts.hindSiliguri(fontSize: 10),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          "From: ${order["pickupAddress"] ?? "N/A"}",
                          style: GoogleFonts.hindSiliguri(fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "To: ${order["dropoffAddress"] ?? "N/A"}",
                          style: GoogleFonts.hindSiliguri(fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.deepOrange[300],
                          ),
                          child: Padding(
                            padding: EdgeInsetsGeometry.only(
                              left: 6,
                              right: 6
                              ),
                            child: Text(
                              " ${order["status"] ?? "N/A"}",
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white
                                ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      "Ksh: ${order["price"] ?? "N/A"}",
                      style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
