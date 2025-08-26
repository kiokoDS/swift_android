import 'package:choice/choice.dart';
import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/match.dart';
import 'package:swift/pages/payments.dart';

class SendPage extends StatefulWidget {
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  var location = LatLng(0, 0);
  var loading = false;
  var token = "";

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
      "dropoffAddress": "Juja",
      "pickupLocation": {
        "latitude": location.latitude,
        "longitude": location.longitude,
      },
      "dropoffLocation": {"latitude": -1.2921, "longitude": 36.8219},
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MatchPage(message: response.data["order"]["orderId"]),
        ),
      );
    } else {
      print(response.statusMessage);
      _isLoading = false;
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
  }

  final locationController = TextEditingController();
  final destinationController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final descriptionController = TextEditingController();
  final mpesaphoneController = PhoneController();
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
                          icon: Icon(Icons.location_on, color: Colors.blue),
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
                    padding: EdgeInsets.only(top: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Contact details",
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
                            borderRadius: BorderRadius.circular(10),
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
}
