import 'dart:ffi';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:choice/choice.dart';
import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:swift/pages/homepage.dart';
import 'package:swift/pages/match.dart';
import 'package:swift/pages/payments.dart';
import 'package:swift/services/nominatimservice.dart';

class SendPage extends StatefulWidget {
  final String? location;
  final bool? throughpass;
  final LatLng? destiny;
  const SendPage({Key? key, this.location, this.throughpass, this.destiny})
    : super(key: key);

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  var location = LatLng(0, 0);
  var destination = LatLng(0, 0);
  var loading = false;
  var token = "";
  bool fareloading = false;
  bool calculatedfare = false;
  var orderid = "";

  //driver details
  var driverphone = "";
  var drivername = "";
  var licenseplate = "";
  bool driverfound = false;

  //order details
  bool promt = false;

  //trip pricing
  var fare = 0;
  var commission = 0.0;
  var base_fare = 0;
  var distance_km = 0;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString("token")!;
    });
    return prefs.getString("token");
  }

  Future<String?> getAddressFromLatLng(double lat, double lon) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1",
    );

    final response = await http.get(
      url,
      headers: {
        "User-Agent": "flutter_app", // required by Nominatim
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Example: full address string
      return data["display_name"];
    } else {
      print("Error: ${response.statusCode}");
      return null;
    }
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

  Future<void> saveTracking() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("tracking", "true");
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
      "origin_lat": location.latitude,
      "origin_lng": location.longitude,
      "dest_lat": destination.latitude,
      "dest_lng": destination.longitude,
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
        distance_km = response.data["distance_km"].toInt();
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

  Future<void> createOrder() async {
    _isLoading = true;
    var key = await getToken();

    var headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${key}',
    };
    var data = json.encode({
      "userId": 1,
      "status": "pending",
      "pickupAddress": locationController.text,
      "pickupContactName": nameController.text,
      "pickupContactPhone": phoneController.text,
      "dropoffAddress": destinationController.text,
      "pickupLocation": {
        "latitude": location.latitude,
        "longitude": location.longitude,
      },
      "dropoffLocation": {
        "latitude": destination.latitude,
        "longitude": destination.longitude,
      },
      "droppffContactName": "jaydee",
    });

    var dio = Dio();
    var response = await dio.request(
      'http://209.126.8.100:4141/api/orders/create',
      options: Options(method: 'POST', headers: headers),
      data: data,
    );

    if (response.statusCode == 201) {
      print(json.encode(response.data["order"]["orderId"]));
      _isLoading = false;
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) =>
      //         MatchPage(message: response.data["order"]["orderId"]),
      //   ),
      // );

      saveTracking();

      var orderid = response.data["order"]["orderId"];

      setState(() {
        this.orderid = orderid.toString();
        promt = true;
      });

      AwesomeDialog(
        context: context,
        dialogBackgroundColor: Colors.white,
        btnOkColor: Colors.deepOrange[700],
        animType: AnimType.scale,
        dialogType: DialogType.info,
        body: Center(
          child: Container(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SingleChildScrollView(
                //controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // --- Title
                    Text(
                      "Are you sure you want to continue?",
                      style: GoogleFonts.inter(
                        decoration: TextDecoration.none,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Fare Breakdown
                    _buildFareRow(
                      "Distance",
                      "${distance_km.toString()} Km",
                      fareloading,
                    ),
                    _buildFareRow(
                      "Commission",
                      "${NumberFormat().format(commission)} Ksh",
                      fareloading,
                    ),
                    _buildFareRow(
                      "Base Rate",
                      "${NumberFormat().format(base_fare)} Ksh",
                      fareloading,
                    ),
                    _buildFareRow(
                      "Fare",
                      "${NumberFormat().format(fare)} Ksh",
                      fareloading,
                      highlight: true,
                    ),

                    const SizedBox(height: 32),

                    // --- Proceed Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 56,
                    //   child: ElevatedButton(
                    //     style: ElevatedButton.styleFrom(
                    //       elevation: 0,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(28),
                    //       ),
                    //       backgroundColor: Colors.deepOrange[700],
                    //     ),
                    //     onPressed: () {
                    //       match();
                    //       // fetchRoute();

                    //       // _mapController.mapEventStream.listen((event) {
                    //       //   if (loading) {
                    //       //     setState(() => loading = false);
                    //       //   }
                    //       // });

                    //       // var keyboardVisibility =
                    //       //     KeyboardVisibilityController();
                    //       // var keyboardSubscription = keyboardVisibility
                    //       //     .onChange
                    //       //     .listen((visible) {
                    //       //       if (visible) {
                    //       //         draggableController.animateTo(
                    //       //           1.0,
                    //       //           duration: const Duration(
                    //       //             milliseconds: 200,
                    //       //           ),
                    //       //           curve: Curves.easeOut,
                    //       //         );
                    //       //       }
                    //       //     });

                    //       // getLocation();

                    //       // // 🔌 connect to WebSocket server
                    //       // wsService.connect("ws://209.126.8.100:8080/ws");

                    //       // // 🔄 start streaming GPS
                    //       // _gpsSub =
                    //       //     Geolocator.getPositionStream(
                    //       //       locationSettings: const LocationSettings(
                    //       //         accuracy: LocationAccuracy.high,
                    //       //         distanceFilter: 1,
                    //       //       ),
                    //       //     ).listen((Position pos) {
                    //       //       final gpsData = jsonEncode({
                    //       //         "lat": pos.latitude,
                    //       //         "lng": pos.longitude,
                    //       //         "user": username,
                    //       //         "timestamp": DateTime.now()
                    //       //             .toIso8601String(),
                    //       //       });
                    //       //       wsService.send(gpsData);
                    //       //     });

                    //       // // 👂 listen for backend messages
                    //       // wsService.stream.listen((message) {
                    //       //   try {
                    //       //     final data = jsonDecode(message);
                    //       //     final orderId = data["order_id"];
                    //       //     final lat = data["lat"];
                    //       //     final lng = data["lng"];

                    //       //     getLocation();

                    //       //     if (orderId == "12345") {
                    //       //       setState(() {
                    //       //         end = LatLng(lat, lng);
                    //       //       });

                    //       //       updateRoutes(
                    //       //         start.latitude,
                    //       //         start.longitude,
                    //       //         lat,
                    //       //         lng,
                    //       //       );

                    //       //       _mapController.move(
                    //       //         LatLng(lat, lng),
                    //       //         18.0,
                    //       //       );

                    //       //       fetchRoute();
                    //       //     }
                    //       //   } catch (e) {
                    //       //     print("Invalid WS message: $e");
                    //       //   }
                    //       // });
                    //     },
                    //     child: Text(
                    //       "Proceed",
                    //       style: GoogleFonts.inter(
                    //         fontSize: 17,
                    //         fontWeight: FontWeight.w800,
                    //         color: Colors.white,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
        title: 'This is Ignored',
        desc: 'This is also Ignored',
        btnOkOnPress: () {
          match();
        },
      ).show();

      //Navigator.pop(context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) =>
      //     Homepage()
      //         //HomePage(tracking: true, promptstart: true, orderid: orderid, currentLocation: location, destination: destination),
      //   ),
      // );
    } else {
      print(response.statusMessage);
      _isLoading = false;
    }
  }

  Future<void> match() async {
    setState(() {
      fareloading = true;
      _isLoading = true;
    });
    var key = await getToken();
    var headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer ${key}',
    };
    var data = {'orderId': orderid};
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
        promt = true;
      });
      

      setState(() {
        fareloading = false;
        _isLoading = false;
      });


      AwesomeDialog(
            context: context,
            animType: AnimType.scale,
            dialogType: DialogType.success,
            dialogBackgroundColor: Colors.white,
            btnOkColor: Colors.deepOrange[700],
            body: Center(child: 
            Container(
                  
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: SingleChildScrollView(
                      //controller: scrollController,
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
                                      child: Image.asset(
                                        "assets/images/driver.png",
                                        width: 50,
                                        height: 50,
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
                                // Row(
                                //   children: [
                                //     Expanded(
                                //       child: ElevatedButton.icon(
                                //         onPressed: () => {},
                                //         style: ElevatedButton.styleFrom(
                                //           backgroundColor: Colors.grey,
                                //           shape: RoundedRectangleBorder(
                                //             borderRadius: BorderRadius.circular(
                                //               10,
                                //             ),
                                //           ),
                                //         ),
                                //         icon: Icon(
                                //           Icons.call,
                                //           color: Colors.white,
                                //         ),
                                //         label: Text(
                                //           "Call",
                                //           style: GoogleFonts.inter(
                                //             fontSize: 14,
                                //             fontWeight: FontWeight.w700,
                                //             color: Colors.white,
                                //           ),
                                //         ),
                                //       ),
                                //     ),
                                //     SizedBox(width: 10),
                                //     Expanded(
                                //       child: ElevatedButton.icon(
                                //         onPressed: () => {},
                                //         style: ElevatedButton.styleFrom(
                                //           backgroundColor: Colors.blue,
                                //           shape: RoundedRectangleBorder(
                                //             borderRadius: BorderRadius.circular(
                                //               10,
                                //             ),
                                //           ),
                                //         ),
                                //         icon: Icon(
                                //           Icons.message,
                                //           color: Colors.white,
                                //         ),
                                //         label: Text(
                                //           "Message",
                                //           style: GoogleFonts.inter(
                                //             fontSize: 14,
                                //             fontWeight: FontWeight.w700,
                                //             color: Colors.white,
                                //           ),
                                //         ),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
            title: 'This is Ignored',
            desc:   'This is also Ignored',
            btnOkOnPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Homepage(),
                  //HomePage(tracking: true, promptstart: true, orderid: orderid, currentLocation: location, destination: destination),
                ),
              );
            },
            ).show();

            
    } else {
      print(response.statusMessage);
      setState(() {
        fareloading = false;
        _isLoading = false;
      });
    }
  }

  void fetchAddress(Lat, Lng) async {
    final address = await getAddressFromLatLng(Lat, Lng);
    print("Address: $address");
    setState(() {
      locationController.text = address!;
    });
  }

  void getLocation() async {
    setState(() {
      loading = true;
    });
    Position position = await _getCurrentLocation();
    print("Lat: ${position.latitude}, Lng: ${position.longitude}");
    fetchAddress(position.latitude, position.longitude);
    print(position);
    setState(() {
      location = LatLng(position.latitude, position.longitude);
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize the map controller
    getLocation();

    if (widget.throughpass == true) {
      setState(() {
        destinationController.text = widget.location!;
        print("-------------------");
        destination = widget.destiny!;
      });
    }
  }

  final locationController = TextEditingController();
  final destinationController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final descriptionController = TextEditingController();
  final mpesaphoneController = PhoneController();
  final TextEditingController _controller = TextEditingController();
  final NominatimService _nominatimService = NominatimService();

  String? selectedCoordinates;
  bool _isLoading = false;

  List<String> choices = ['Mpesa', 'Cash'];

  String? selectedValue;

  void setSelectedValue(String? value) {
    setState(() => selectedValue = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Send to",
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Location details",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),

                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: locationController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Current location",
                          suffixIcon: loading
                              ? LoadingIndicator(
                                  indicatorType: Indicator.ballPulseSync,
                                  colors: const [Colors.deepOrange],
                                  strokeWidth: 2,
                                )
                              : null,
                          icon: Icon(Icons.location_on, color: Colors.green),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: destinationController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter delivery location",
                          icon: Icon(
                            Icons.location_pin,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TypeAheadField<Map<String, dynamic>>(
                              direction: VerticalDirection.up,
                              suggestionsCallback: (pattern) async {
                                if (pattern.isEmpty) return [];
                                return await _nominatimService.searchLocations(
                                  pattern,
                                );
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

                                  destination = LatLng(
                                    double.parse(suggestion["lat"]),
                                    double.parse(suggestion["lon"]),
                                  );
                                  destinationController.text =
                                      suggestion["displayName"];
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
                                _controller.value =
                                    controller.value; // keep sync if needed
                                return TextField(
                                  style: GoogleFonts.inter(),
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: "Where to?",
                                    border: InputBorder.none,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Receiver details",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Contact Name",
                          //icon: Icon(FeatherIcons.user),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.phone,
                        controller: phoneController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Contact phone number",
                          //icon: Icon(FeatherIcons.phoneCall),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: 3,
                        minLines: 3,
                        controller: descriptionController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Description (optional)",
                          //icon: Icon(Icons.location_on),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Details",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),

                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      children: choices.map((choice) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: 10),
                            ChoiceChip(
                              selectedColor: Colors.orange[100],
                              backgroundColor: Colors.white,
                              selected: selectedValue == choice,
                              onSelected: (_) => setSelectedValue(choice),
                              label: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  choice == "Mpesa"
                                      ? Image.asset(
                                          "assets/images/mpesa.png",
                                          fit: BoxFit.contain,
                                          height: 20,
                                        )
                                      : Image.asset(
                                          "assets/images/cash.png",
                                          fit: BoxFit.contain,
                                          height: 20,
                                        ),
                                  SizedBox(width: 10),
                                  Text(
                                    choice,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: selectedValue == "Mpesa"
                          ? Container(
                              height: 50,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: PhoneFormField(
                                textAlign: TextAlign.center,
                                controller: mpesaphoneController,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Contact phone number",
                                  //icon: Icon(FeatherIcons.phoneCall),
                                ),
                              ),
                            )
                          : SizedBox.shrink(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          backgroundColor: Colors.orange[700],
                        ),
                        onPressed: () {
                          print(location);
                          print(destinationController.text);
                          print(descriptionController.text);
                          print(nameController.text);
                          print(phoneController.text);

                          if (location.latitude.isNaN ||
                              destinationController.text.isEmpty ||
                              nameController.text.isEmpty ||
                              phoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text("Please fill all fields"),
                              ),
                            );
                          } else {
                            calculateFare();
                            createOrder();
                          }

                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (_) => MatchPage()),
                          // );
                        },
                        child: _isLoading
                            ? LoadingIndicator(
                                indicatorType: Indicator.ballPulseSync,
                                colors: const [Colors.white],
                                strokeWidth: 2,
                              )
                            : Text(
                                "Next",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
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

  Widget _buildFareRow(
    String label,
    String value,
    bool loading, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Skeletonizer(
            enabled: loading,
            child: Text(
              "$label:",
              style: GoogleFonts.inter(
                decoration: TextDecoration.none,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Skeletonizer(
            enabled: loading,
            child: Text(
              value,
              style: GoogleFonts.inter(
                decoration: TextDecoration.none,
                fontSize: 16,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
                color: highlight ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
