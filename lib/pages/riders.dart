import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    var key = await getToken();
    var headers = {'Authorization': 'Bearer $key'};

    try {
      var response = await dio.request(
        'http://209.126.8.100:4141/api/drivers/all?page=0',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        setState(() {
          orders = response.data["items"] ?? response.data;
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
              padding: EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                var ff = DateTime.tryParse(order["createdAt"]);

                return RiderCard(
                  name: order["User"]["Username"] ?? "N/A",
                  licensePlate: order["licensePlate"] ?? "N/A",
                  rating: order["rating"]?.toString() ?? "N/A",
                  createdAt: ff,
                );
              },
            ),
    );
  }
}

class RiderCard extends StatelessWidget {
  final String name;
  final String licensePlate;
  final String rating;
  final DateTime? createdAt;

  const RiderCard({
    super.key,
    required this.name,
    required this.licensePlate,
    required this.rating,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      //color: Colors.orange[100],
      color: Colors.grey[100],
      margin: EdgeInsets.symmetric(vertical: 8),

      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Rider Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage("assets/images/rider.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 16),
            // Rider Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Plates: $licensePlate",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Last delivery: ${createdAt != null ? timeago.format(createdAt!) : "N/A"}",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        "Report",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
