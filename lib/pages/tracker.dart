import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' hide MapController;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/services/nominatimservice.dart';

class Tracker extends StatefulWidget {

  final String? orderid;

  const Tracker({Key? key, this.orderid}) : super(key: key);

  @override
  State<Tracker> createState() => _TrackerState();
}

class _TrackerState extends State<Tracker> {
  final LatLng center = LatLng(-1.286389, 36.817223); // Nairobi
  final LatLng newPoint = LatLng(-1.2921, 36.8219); // Example (Kenyatta Ave)

  LatLng start = LatLng(-1.286389, 36.817223);
  LatLng end = LatLng(-1.2921, 36.8219);

  //mapdata
  final MapController _mapController = MapController();
  final NominatimService _nominatimService = NominatimService();
  List<LatLng> routePoints = [];

  bool loading = false;

  var username = "";
  var token = "";
  var userid = "";

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

  Future<void> getOrderDetails() async {
    try {
      var key = await getToken();
      final dio = Dio();
      final response = await dio.request(
        'http://209.126.8.100:4141/api/orders/${widget.orderid}/details',
        options: Options(
          method: 'GET',
          headers: {
            'Authorization': 'Bearer $key',
          },
        ),
      );

      if (response.statusCode == 200) {
        print(json.encode(response.data));
      } else {
        print(response.statusMessage);
      }
    } catch (e) {
      print('Error fetching order details: $e');
    }
  }

  @override
  void initState(){
    super.initState();
    getToken();
    _getCurrentLocation().then((position) {
      setState(() {
        start = LatLng(position.latitude, position.longitude);
        // For demonstration, let's set the end point a bit north-east of the start
        end = LatLng(position.latitude + 0.01, position.longitude + 0.01);
        routePoints = [start, end];
      });
    }).catchError((e) {
      print("Error getting location: $e");
    });

    getOrderDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white,title: Text("Order Tracker", style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.black
      ),)),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 18.0
            ),
            mapController: _mapController,
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=5pYqr4DbTOErEL2iL0ul',
                userAgentPackageName: 'com.kios19.swift',
                tileProvider: NetworkTileProvider(), // optional, explicit
                tileSize: 256,
                keepBuffer: 2,
                maxZoom: 20,
                minZoom: 10,
              ),
            ])
        ],
      ),
    );
  }
}
