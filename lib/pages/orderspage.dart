import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/tracker.dart';

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
        backgroundColor: Colors.white,
        title: Text(
          "Orders",
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
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
                    onTap: (){
                      print(order["orderId"]);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Tracker(orderid: order["orderId"]), // Replace with your detail page
                        ),
                      );  
                    },
                    title: Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Image.asset(
                                "assets/images/box.png",
                                fit: BoxFit.cover,
                                height: 30,
                                width: 30,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsGeometry.only(left: 10),
                            child: Text(
                              "${order["orderId"] ?? "N/A"}",
                              style: GoogleFonts.inter(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          "From: ${order["pickupAddress"] ?? "N/A"}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "To: ${order["dropoffAddress"] ?? "N/A"}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),

                        LinearProgressIndicator(
                          value: 0.2, // value between 0.0 and 1.0
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: Colors.grey[300],
                          color: Colors.deepOrange, // filled color
                        ),

                        // Container(
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(10),
                        //     color: Colors.grey[700],
                        //   ),
                        //   child: Padding(
                        //     padding: EdgeInsetsGeometry.only(
                        //       left: 10,
                        //       right: 10,
                        //     ),
                        //     child: Text(
                        //       " ${order["status"] ?? "N/A"}",
                        //       style: GoogleFonts.inter(
                        //         fontSize: 10,
                        //         fontWeight: FontWeight.w600,
                        //         color: Colors.white,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                    trailing: Text(
                      "KES: ${order["price"] ?? "N/A"}",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
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
