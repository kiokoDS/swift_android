import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:primer_progress_bar/primer_progress_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/tracker.dart';

class OrdersPage extends StatefulWidget {
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

// Use the Segment class exported by the primer_progress_bar package
// (removed local duplicate to avoid type conflict with package's Segment).

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
          ? Center(
              child: Container(
                height: 100,
                child: LoadingIndicator(
                  indicatorType: Indicator.ballPulseSync,
                  colors: const [Colors.deepOrangeAccent],
                  strokeWidth: 2,
                ),
              ),
            )
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
                    onTap: () {
                      print(order["orderId"]);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Tracker(
                            orderid: order["orderId"],
                          ), // Replace with your detail page
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
                          Container(
                            width: 210,
                            child: Padding(
                              padding: EdgeInsetsGeometry.only(left: 10),
                              child: Text(
                                overflow: TextOverflow.ellipsis,
                                "${order["orderId"] ?? "N/A"}",
                                style: GoogleFonts.inter(fontSize: 10),
                              ),
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

                        PrimerProgressBar(
                          segments: getSegments(
                            order["status"] ?? "pending",
                          ), // or 'pending' / 'complete'
                          
                        ),

                        SizedBox(height: 10),

                        Text(
                            "Click to track your order status",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey[600],
                            ),
                          )
                        
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

  List<Segment> getSegments(String state) {
    // Default percentages
    int pendingValue = 0;
    int inTransitValue = 0;
    int doneValue = 0;

    // Assign percentage based on current state
    switch (state) {
      case 'pending':
        pendingValue = 80;
        inTransitValue = 14;
        doneValue = 0;
        break;
      case 'in-transit':
        pendingValue = 0;
        inTransitValue = 80;
        doneValue = 14;
        break;
      case 'complete':
        pendingValue = 0;
        inTransitValue = 0;
        doneValue = 100;
        break;
      default:
        break;
    }

    return [
      Segment(
        value: pendingValue,
        color: Colors.blueGrey,
        valueLabel: Text(
          "$pendingValue%",
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        label: Text(
          "Rider Coming",
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
      Segment(
        value: inTransitValue,
        color: Colors.deepOrange,
        valueLabel: Text(
          "$inTransitValue%",
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        label: Text(
          "In Progress",
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
      Segment(
        value: doneValue,
        color: Colors.green,
        valueLabel: Text(
          "$doneValue%",
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        label: Text(
          "Done",
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
    ];
  }
}
