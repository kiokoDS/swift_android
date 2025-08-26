import 'dart:convert';

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/receive.dart';
import 'package:swift/pages/request.dart';
import 'package:swift/pages/riders.dart';
import 'package:swift/pages/send.dart';
import 'package:swift/services/nominatimservice.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LatLng center = LatLng(-1.286389, 36.817223); // Nairobi
  final LatLng newPoint = LatLng(-1.2921, 36.8219); // Example (Kenyatta Ave)

  final LatLng start = LatLng(-1.286389, 36.817223);
  final LatLng end = LatLng(-1.2921, 36.8219);

  bool loading = false;
  final MapController _mapController = MapController();

  var username = "";
  var token = "";

  final NominatimService _nominatimService = NominatimService();
  String? selectedCoordinates;

  List<LatLng> routePoints = [];

  final SearchController = TextEditingController();

  final TextEditingController _controller = TextEditingController();

  final DraggableScrollableController draggableController =
      DraggableScrollableController();

  double sheetExtent = 0.8; // track current extent
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString("token")!;
      username = prefs.getString("username")!;
    });
    return prefs.getString("token");
  }

  Future<void> fetchRoute() async {
    setState(() {
      loading = true;
    });
    const apiKey =
        "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjZjNGY5M2ViNzJkMTQ1ODhiZGU1MDNjNjRlMjQxOTk3IiwiaCI6Im11cm11cjY0In0="; // 🔑 put your ORS key here
    final url =
        "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final coords = data["features"][0]["geometry"]["coordinates"] as List;

      setState(() {
        routePoints = coords
            .map((c) => LatLng(c[1], c[0])) // ORS gives [lon, lat]
            .toList();
      });
      setState(() {
        loading = true;
      });
    } else {
      print("Failed to fetch route: ${response.body}");
      setState(() {
        loading = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    draggableController.addListener(() {
      setState(() {
        sheetExtent = draggableController.size;
      });
    });
    getToken();
    fetchRoute();
    _mapController.mapEventStream.listen((event) {
      if (loading) {
        setState(() {
          loading = false;
        });
      }
    });
    var keyboardVisibility = KeyboardVisibilityController();

    var keyboardSubscription = keyboardVisibility.onChange.listen((visible) {
      if (visible) {
        draggableController.animateTo(
          1.0,
          duration: Duration(milliseconds: 200),
          curve: Curves.bounceIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 18.0),
          mapController: _mapController,
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=5pYqr4DbTOErEL2iL0ul',
              userAgentPackageName: 'com.kios19.swift',
              tileProvider: NetworkTileProvider(), // optional, explicit
            ),
            // 🔵 Polyline between them
            PolylineLayer<Object>(
              polylines: routePoints.isNotEmpty
                  ? [
                      Polyline<Object>(
                        points: routePoints,
                        strokeWidth: 6,
                        color: Colors.blue,
                        strokeCap: StrokeCap.round,
                      ),
                    ]
                  : [],
            ),

            MarkerLayer(
              markers: [
                Marker(
                  point: start,
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    "assets/images/box.png",
                    width: 40,
                    height: 40,
                  ),
                ),
                Marker(
                  point: end,
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    "assets/images/rider.png",
                    width: 40,
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 40,
          left: 15,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Builder(
                builder: (context) => IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(FeatherIcons.menu, size: 26),
                ),
              ),
            ),
          ),
        ),
        DraggableScrollableSheet(
          controller: draggableController,
          initialChildSize: 0.8,
          minChildSize: 0.2,
          maxChildSize: 1.0,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: SingleChildScrollView(
                    controller: scrollController,
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

                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1.0,
                                child: child,
                              ),
                            );
                          },
                          child: sheetExtent >= 0.95
                              ? Padding(
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
                                ) // show directly under title
                              : SizedBox.shrink(key: ValueKey("empty")),
                        ),

                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1.0,
                                child: child,
                              ),
                            );
                          },
                          child: sheetExtent == 1.0
                              ? _buildSearchBox()
                              : SizedBox.shrink(key: ValueKey("empty")),
                        ),

                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1.0,
                                child: child,
                              ),
                            );
                          },
                          child: sheetExtent < 0.95
                              ? Padding(
                                  padding: EdgeInsets.only(top: 20, bottom: 6),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Lets send a package",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                )
                              // show directly under title
                              : SizedBox.shrink(key: ValueKey("empty")),
                        ),

                        // ✅ search box floats up when minimized
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1.0,
                                child: child,
                              ),
                            );
                          },
                          child: sheetExtent <= 0.35
                              ? _buildSearchBox() // show directly under title
                              : SizedBox.shrink(key: ValueKey("empty")),
                        ),

                        Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 20),
                          child: Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 20),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  NeverScrollableScrollPhysics(), // ✅ disables nested scrolling
                              itemCount: 4,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                            ),
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
                        // ✅ search box when expanded
                        AnimatedSwitcher(
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1.0,
                                child: child,
                              ),
                            );
                          },
                          duration: Duration(milliseconds: 300),
                          child: sheetExtent > 0.3 && sheetExtent < 0.95
                              ? _buildSearchBox()
                              : SizedBox.shrink(key: ValueKey("empty")),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
        child: TypeAheadField<Map<String, dynamic>>(
          suggestionsCallback: (pattern) async {
            if (pattern.isEmpty) return [];
            return await _nominatimService.searchLocations(pattern);
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              title: Text(
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
    );
  }

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
      "title": "Request",
      "subtitle": "special request",
      "asset": "assets/images/request.png",
      "page": Requestpage(),
    },
    {
      "title": "Riders",
      "subtitle": "previous riders",
      "asset": "assets/images/rider.png",
      "page": Riders(),
    },
  ];
}
