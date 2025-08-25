import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';

class Requestpage extends StatefulWidget {
  @override
  State<Requestpage> createState() => _RequestPageState();
}

class _RequestPageState extends State<Requestpage> {
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

  void getLocation() async {
    Position position = await _getCurrentLocation();
    print("Lat: ${position.latitude}, Lng: ${position.longitude}");
  }

  @override
  void initState() {
    super.initState();
    // Initialize the map controller
    getLocation();
  }

  final locationController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Special Request", style: GoogleFonts.hindSiliguri(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(padding: EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Location details",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),),
                Divider(),

                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: locationController,
                      style: GoogleFonts.hindSiliguri(fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Current location",
                        icon: Icon(Icons.location_on),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: locationController,
                      style: GoogleFonts.hindSiliguri(fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter delivery location",
                        icon: Icon(FeatherIcons.mapPin),
                      ),
                    ),
                  ),
                ),

                Padding(padding: EdgeInsets.only(top: 40)
                ,child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Contact details",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),),

                Divider(),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: locationController,
                      style: GoogleFonts.hindSiliguri(fontSize: 14),
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: locationController,
                      style: GoogleFonts.hindSiliguri(fontSize: 14),
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      style: GoogleFonts.hindSiliguri(fontSize: 14),
                      maxLines: 3,
                      minLines: 3,
                      controller: locationController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Description (optional)",
                        //icon: Icon(Icons.location_on),
                      ),
                    ),
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

                          },
                          child: _isLoading
                              ? LoadingIndicator(
                                  indicatorType: Indicator.ballSpinFadeLoader,
                                  colors: const [Colors.white],
                                  strokeWidth: 2,
                                )
                              : Text(
                                  "Submit",
                                  style: GoogleFonts.hindSiliguri(
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
    );
  }
}
