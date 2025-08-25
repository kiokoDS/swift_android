import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersPage extends StatefulWidget {
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  var token = "";

  final Dio dio = Dio();
  List<dynamic> orders = [];
  bool isLoading = true;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString("token")!;
    });
    return prefs.getString("token");
  }

  @override
  void initState() {
    super.initState();
    getToken();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    var key = await getToken();
    var headers = {'Authorization': "Bearer ${key}"};

    try {
      var response = await dio.request(
        'http://209.126.8.100:4141/api/orders/all?page=0',
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
        print("Token: $token");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Exception: $e");
      print(headers);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Orders",
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : orders.isEmpty
          ? Center(child: Text("No orders found"))
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
                            padding: EdgeInsetsGeometry.only(left: 6, right: 6),
                            child: Text(
                              " ${order["status"] ?? "N/A"}",
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
