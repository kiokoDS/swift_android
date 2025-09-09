import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:latlong2/latlong.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:swift/pages/receive.dart';
import 'package:swift/pages/request.dart';
import 'package:swift/pages/riders.dart';
import 'package:swift/pages/send.dart';
import 'package:swift/services/nominatimservice.dart';
import 'package:swift/services/websocketservice.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomePage extends StatefulWidget {
  final bool? tracking;
  final bool? promptstart;
  final String? orderid;
  final LatLng? currentLocation;
  final LatLng? destination;
  const HomePage({
    Key? key,
    this.tracking,
    this.promptstart,
    this.orderid,
    this.currentLocation,
    this.destination,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LatLng center = LatLng(-1.286389, 36.817223); // Nairobi
  final LatLng newPoint = LatLng(-1.2921, 36.8219); // Example (Kenyatta Ave)

  LatLng start = LatLng(-1.286389, 36.817223);
  LatLng end = LatLng(-1.2921, 36.8219);

  bool loading = false;
  bool activeorder = true;
  bool checkingorders = true;
  bool tracking = false;
  bool fareloading = false;
  bool calculatedfare = false;
  var prompting = false;
  bool driverfound = false;

  bool _isDraggingPin = false;
  LatLng? _draggedPosition;

  //pricing
  var fare = 0;
  var commission = 0.0;
  var base_fare = 0;
  var distance_km = 0;

  final MapController _mapController = MapController();

  var username = "";
  var token = "";
  var userid = "";

  var driverphone = "";
  var drivername = "";
  var licenseplate = "";

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

  Future<Position> _getCurrentLocation() async {
    // Ask for permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  final Dio dio = Dio();

  Future<void> fetchPendingOrder() async {
    var key = await getToken();
    var headers = {'Authorization': "Bearer ${key}"};

    setState(() {
      checkingorders = true;
    });

    try {
      var response = await dio.request(
        'http://209.126.8.100:4141/api/orders/pending',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        print("Pending orders: ${response.data}");
        setState(() {
          checkingorders = false;
        });
      } else {
        print("===============+++++++++++++++++++++++++");
        print("Error: ${response.statusMessage}");
        print("Token: $token");
        setState(() => checkingorders = false);
      }
    } catch (e) {
      print("===============+++++++++++++++++++++++++");
      print("Exception: $e");
      print(headers);
      setState(() => checkingorders = false);
    }
  }

  Future<void> match() async {
    setState(() {
      fareloading = true;
    });
    var key = await getToken();
    var headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer ${key}',
    };
    var data = {'orderId': widget.orderid};
    var dio = Dio();
    var response = await dio.request(
      'http://209.126.8.100:4141/api/orders/match-driver',
      options: Options(method: 'POST', headers: headers),
      data: data,
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
      setState(() {
        driverphone = response.data["userPhone"];
        drivername = response.data["userName"];
        licenseplate = response.data["licensePlate"];
        driverfound = true;
        prompting = false;
      });

      setState(() {
        fareloading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        draggableController.animateTo(
          0.4,
          duration: Duration(milliseconds: 200),
          curve: Curves.bounceIn,
        );
      });
    } else {
      print(response.statusMessage);
      setState(() {
        fareloading = false;
      });
    }
  }

  void getLocation() async {
    setState(() {
      loading = true;
    });
    Position position = await _getCurrentLocation();
    print("Got location: $position");
    print("Lat: ${position.latitude}, Lng: ${position.longitude}");

    setState(() {
      start = LatLng(position.latitude, position.longitude);
    });
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

  Future<void> calculateFare() async {
    setState(() {
      fareloading = true;
    });
    var key = await getToken();

    var headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${key}',
    };
    var data = json.encode({
      "origin_lat": widget.currentLocation!.latitude,
      "origin_lng": widget.currentLocation!.longitude,
      "dest_lat": widget.destination!.latitude,
      "dest_lng": widget.destination!.longitude,
      "demand_factor,omitempty": 1.0, // default 1.0
      "average_speed_kmph,omitempty": 80, // default 30
    });
    var dio = Dio();
    var response = await dio.request(
      'http://209.126.8.100:4141/api/fare/calculate',
      options: Options(method: 'POST', headers: headers),
      data: data,
    );

    if (response.statusCode == 200) {
      setState(() {
        fare = response.data["total_after_min"].toInt();
        commission = response.data["platform_commission"];
        base_fare = response.data["base_fare"].toInt();
        calculatedfare = true;
        fareloading = false;
      });
    } else {
      print(response.statusMessage);

      setState(() {
        calculatedfare = true;
        fareloading = false;
      });
    }
  }

  Future<void> updateRoutes(startlat, startlng, endlat, endlng) async {
    const apiKey =
        "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjZjNGY5M2ViNzJkMTQ1ODhiZGU1MDNjNjRlMjQxOTk3IiwiaCI6Im11cm11cjY0In0="; // 🔑 put your ORS key here
    final url =
        "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${startlng},${startlat}&end=${endlng},${endlat}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print("---------------------------------");
      print(data["features"][0]);
      print("---------------------------------");

      final coords = data["features"][0]["geometry"]["coordinates"] as List;

      routePoints.clear();

      setState(() {
        routePoints = coords
            .map((c) => LatLng(c[1], c[0])) // ORS gives [lon, lat]
            .toList();
      });
    } else {
      print("Failed to fetch route: ${response.body}");
    }
  }

  final channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.100.4:8080/ws'), // 👈 your Go WS server
  );

  final wsService = WebSocketService();
  StreamSubscription<Position>? _gpsSub;

  @override
  void initState() {
    super.initState();

    fetchPendingOrder();

    draggableController.addListener(() {
      setState(() {
        sheetExtent = draggableController.size;
      });
    });

    getToken();
    // fetchRoute();

    // _mapController.mapEventStream.listen((event) {
    //   if (loading) {
    //     setState(() {
    //       loading = false;
    //     });
    //   }
    // });

    // var keyboardVisibility = KeyboardVisibilityController();

    // var keyboardSubscription = keyboardVisibility.onChange.listen((visible) {
    //   if (visible) {
    //     draggableController.animateTo(
    //       1.0,
    //       duration: Duration(milliseconds: 200),
    //       curve: Curves.bounceIn,
    //     );
    //   }
    // });

    // getLocation();

    // // 🔌 connect to WebSocket server
    // wsService.connect("ws://192.168.100.4:8080/ws");

    // // 🔄 start streaming GPS
    // _gpsSub =
    //     Geolocator.getPositionStream(
    //       locationSettings: const LocationSettings(
    //         accuracy: LocationAccuracy.high,
    //         distanceFilter: 1, // send update o36.8219nly if moved 5m+
    //       ),
    //     ).listen((Position pos) {
    //       final gpsData = jsonEncode({
    //         "lat": pos.latitude,
    //         "lng": pos.longitude,
    //         "user": username,
    //         "timestamp": DateTime.now().toIso8601String(),
    //       });

    //       wsService.send(gpsData);
    //     });

    // // 👂 listen for backend messages
    // wsService.stream.listen((message) {
    //   try {
    //     final data = jsonDecode(message);
    //     final orderId = data["order_id"];
    //     final user = data["username"];
    //     final lat = data["lat"];
    //     final lng = data["lng"];

    //     getLocation();

    //     // ✅ filter for the logged-in user + order
    //     if (orderId == "12345") {
    //       print("📩 Update for me: $lat,$lng");
    //       // e.g. add a marker to the map
    //       setState(() {
    //         //routePoints.add(LatLng(lat, lng));
    //         end = LatLng(lat, lng);
    //       });

    //       updateRoutes(start.latitude, start.longitude, lat, lng);

    //       _mapController.move(LatLng(lat, lng), 18.0);

    //       fetchRoute();
    //     }
    //   } catch (e) {
    //     print("Invalid WS message: $e");
    //   }
    // });

    if (widget.tracking == true && widget.promptstart == true) {
      setState(() {
        prompting = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        calculateFare();
      });
    }
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (checkingorders) {
      return Container(
        child: Center(
          child: Container(
            height: 50,
            child: LoadingIndicator(
              indicatorType: Indicator.ballPulseSync,
              colors: const [Colors.deepOrange],
              strokeWidth: 2,
            ),
          ),
        ),
      );
    } else {
      return Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 18.0,
              onTap: _isDraggingPin
                  ? (_, point) {
                      setState(() {
                        _draggedPosition = point;
                      });
                      _getReverseGeocode(point);
                    }
                  : null,
            ),
            mapController: _mapController,
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=5pYqr4DbTOErEL2iL0ul',
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
                    width: 30,
                    height: 30,
                    child: Icon(
                      Icons.assistant_navigation,
                      color: Colors.black,
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
              // Add draggable marker when in drag mode
              if (_isDraggingPin && _draggedPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _draggedPosition!,
                      width: 50,
                      height: 50,
                      child: Column(
                        children: [
                          Icon(Icons.place, color: Colors.deepOrange, size: 40),
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              'Drag to adjust',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
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
            snap: false,
            snapSizes: [0.2, 0.8, 1.0],
            controller: draggableController,
            initialChildSize: 0.8,
            minChildSize: 0.2,
            maxChildSize: 1.0,
            builder: (context, scrollController) {
              if (widget.tracking == true && prompting == true) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                      child: Center(
                        child: Column(
                          children: [
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 1,
                                  ),
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
                              padding: EdgeInsets.only(top: 40, bottom: 20),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Are you sure you want to continue?",
                                  style: GoogleFonts.inter(
                                    decoration: TextDecoration.none,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(top: 20, bottom: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Skeletonizer(
                                    enabled: fareloading,
                                    child: Text(
                                      "Distance: ",
                                      style: GoogleFonts.inter(
                                        decoration: TextDecoration.none,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Skeletonizer(
                                    enabled: fareloading,
                                    child: Text(
                                      distance_km.toString() + " km",
                                      style: GoogleFonts.inter(
                                        decoration: TextDecoration.none,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 0, bottom: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Skeletonizer(
                                    enabled: fareloading,
                                    child: Text(
                                      "Commission : ",
                                      style: GoogleFonts.inter(
                                        decoration: TextDecoration.none,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Skeletonizer(
                                    enabled: fareloading,
                                    child: Text(
                                      NumberFormat().format(commission) +
                                          " kes ",
                                      style: GoogleFonts.inter(
                                        decoration: TextDecoration.none,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 0, bottom: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Skeletonizer(
                                    enabled: fareloading,
                                    child: Text(
                                      "Base rate: ",
                                      style: GoogleFonts.inter(
                                        decoration: TextDecoration.none,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Skeletonizer(
                                    enabled: fareloading,
                                    child: Text(
                                      NumberFormat().format(base_fare) +
                                          " kes ",
                                      style: GoogleFonts.inter(
                                        decoration: TextDecoration.none,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 0, bottom: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Skeletonizer(
                                    enabled: fareloading,
                                    child: Text(
                                      "Fare: ",
                                      style: GoogleFonts.inter(
                                        decoration: TextDecoration.none,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Skeletonizer(
                                    enabled: fareloading,
                                    child: Text(
                                      NumberFormat().format(fare) + " kes ",
                                      style: GoogleFonts.inter(
                                        decoration: TextDecoration.none,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.deepOrange[700],
                                ),
                                onPressed: () {
                                  // setState(() {
                                  //   prompting = false;
                                  // });
                                  match();

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

    getLocation();

    // 🔌 connect to WebSocket server
    wsService.connect("ws://192.168.100.4:8080/ws");

    // 🔄 start streaming GPS
    _gpsSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1, // send update o36.8219nly if moved 5m+
          ),
        ).listen((Position pos) {
          final gpsData = jsonEncode({
            "lat": pos.latitude,
            "lng": pos.longitude,
            "user": username,
            "timestamp": DateTime.now().toIso8601String(),
          });

          wsService.send(gpsData);
        });

    // 👂 listen for backend messages
    wsService.stream.listen((message) {
      try {
        final data = jsonDecode(message);
        final orderId = data["order_id"];
        final user = data["username"];
        final lat = data["lat"];
        final lng = data["lng"];

        getLocation();

        // ✅ filter for the logged-in user + order
        if (orderId == "12345") {
          print("📩 Update for me: $lat,$lng");
          // e.g. add a marker to the map
          setState(() {
            //routePoints.add(LatLng(lat, lng));
            end = LatLng(lat, lng);
          });

          updateRoutes(start.latitude, start.longitude, lat, lng);

          _mapController.move(LatLng(lat, lng), 18.0);

          fetchRoute();
        }
      } catch (e) {
        print("Invalid WS message: $e");
      }
    });

                                },
                                child: Text(
                                  "Proceed",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else if (widget.tracking == true &&
                  prompting == false &&
                  driverfound == true) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Driver info
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          drivername,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.orangeAccent[400],
                                              size: 16,
                                            ),
                                            Text(
                                              "4.8",
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                //fontWeight: FontWeight.w800,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Spacer(),
                                    Text(
                                      licenseplate,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Status row
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_bike,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Rider is on the way...",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.call,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          "Call",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.message,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          "Message",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
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
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 1,
                                  ),
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
                                      padding: EdgeInsets.only(
                                        top: 20,
                                        bottom: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: IconButton(
                                              onPressed: () {
                                                Scaffold.of(
                                                  context,
                                                ).openDrawer();
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
                                      padding: EdgeInsets.only(
                                        top: 20,
                                        bottom: 6,
                                      ),
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
                                          builder: (_) =>
                                              item["page"] as Widget,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(0, 1),
                                    end: Offset(0, 0),
                                  ).animate(animation),
                                  //opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    //axisAlignment: -1.0,
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
              }
            },
          ),
        ],
      );
    }
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
              onPressed: () {
                setState(() {
                  _isDraggingPin = true;
                });
                // Center map on current location
                _mapController.move(start, 18);
              },
            ),
          ],
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
      "title": "Schedule",
      "subtitle": "deliver later",
      "asset": "assets/images/hglass.png",
      "page": Requestpage(),
    },
    {
      "title": "Riders",
      "subtitle": "previous riders",
      "asset": "assets/images/rider.png",
      "page": Riders(),
    },
  ];

  Future<void> _getReverseGeocode(LatLng point) async {
    try {
      final address = await _nominatimService.getAddressFromCoordinates(
        point.latitude,
        point.longitude,
      );

      setState(() {
        _controller.text = address['display_name'];
      });

      // Optional: Navigate to send page with selected location
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendPage(
            location: address['display_name'],
            throughpass: true,
            destiny: point,
          ),
        ),
      );

      // Reset drag mode
      setState(() {
        _isDraggingPin = false;
        _draggedPosition = null;
      });
    } catch (e) {
      print('Error getting address: $e');
    }
  }
}
