import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/receive.dart';
import 'package:swift/pages/request.dart';
import 'package:swift/pages/riders.dart';
import 'package:swift/pages/send.dart';
import 'package:swift/pages/ui/Etacard.dart';
import 'package:swift/services/nominatimservice.dart';

class Homepage extends StatefulWidget {
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final NominatimService _nominatimService = NominatimService();
  final TextEditingController _controller = TextEditingController();
  bool _isDraggingPin = false;
  LatLng? _draggedPosition;
  String? selectedCoordinates;

  var token = "";
  final Dio dio = Dio();
  List<dynamic> orders = [];
  bool isLoading = true;

  final List<Map<String, dynamic>> items = [
    {
      "title": "Send",
      "subtitle": "package delivery",
      "asset": "assets/images/box.png",
      "page": SendPage(),
    },
    {
      "title": "Receive",
      "subtitle": "package delivery",
      "asset": "assets/images/hands.png",
      "page": Receivepage(),
    },
    {
      "title": "Schedule",
      "subtitle": "deliver later",
      "asset": "assets/images/mail.png",
      "page": Requestpage(),
    },
    {
      "title": "Riders",
      "subtitle": "previous riders",
      "asset": "assets/images/rider.png",
      "page": Riders(),
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: SingleChildScrollView(
              //controller: scrollController,
              child: Column(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 6),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: IconButton(
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                            icon: Icon(Icons.menu),
                          ),
                        ),
                        Text(
                          "Lets send a package",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSearchBox(),
                  

                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 20),
                    child: Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // ✅ disables nested scrolling
                        itemCount: 4,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 4 / 3,
                            ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => item["page"] as Widget,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      item["asset"] as String,
                                      width: 50,
                                      height: 50,
                                    ),
                                    Text(
                                      item["title"] as String,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      item["subtitle"] as String,
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  isLoading
                      ? CircularProgressIndicator()
                      : Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: SingleChildScrollView(
                            child: Column(
                              children: orders.map((order) {
                                return Padding(padding: EdgeInsets.only(bottom: 10), child: EtaCard(
                                  driverName: "driver1",
                                  etaText: "5 mins",
                                ));
                              }).toList(),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: TypeAheadField<Map<String, dynamic>>(
                direction: VerticalDirection.down,
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) return [];
                  return await _nominatimService.searchLocations(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(13),
                    child: Text(
                      suggestion["displayName"],
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  );
                },
                onSelected: (suggestion) {
                  setState(() {
                    _controller.text = suggestion["displayName"];
                    selectedCoordinates =
                        "Lat: ${suggestion["lat"]}, Lng: ${suggestion["lon"]}";
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SendPage(
                        location: suggestion["displayName"],
                        throughpass: true,
                        destiny: LatLng(
                          double.tryParse(suggestion["lat"])!,
                          double.tryParse(suggestion["lon"])!,
                        ),
                      ),
                    ),
                  );
                },
                // 👇 instead of textFieldConfiguration
                builder: (context, controller, focusNode) {
                  _controller.value = controller.value; // keep sync if needed
                  return TextField(
                    style: GoogleFonts.inter(),
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: "Enter location",
                      border: InputBorder.none,
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.place, color: Colors.deepOrange),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
