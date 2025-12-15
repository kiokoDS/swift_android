import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' hide MapController;
// import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:new_loading_indicator/new_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/services/nominatimservice.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_logs/flutter_logs.dart';
import 'package:swift/services/websocketservice.dart';

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

  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? lineManager;

  //mapdata
  final MapController _mapController = MapController();
  final NominatimService _nominatimService = NominatimService();

  List<LatLng> routePoints = [];

  bool loading = false;

  var username = "";
  var token = "";
  var userid = "";
  var status = "";
  var orderid = "";

  final wsService = WebSocketService();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString("token")!;
      username = prefs.getString("username")!;
    });

    return prefs.getString("token");
  }

  // Future<Position> _getCurrentLocation() async {
  //   // Ask for permission
  //   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return Future.error('Location services are disabled.');
  //   }

  //   LocationPermission permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       return Future.error('Location permissions are denied');
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     return Future.error('Location permissions are permanently denied.');
  //   }

  //   // Get current position
  //   return await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high,
  //   );
  // }

  Future<void> getOrderDetails() async {
    try {
      setState(() {
        loading = true;
      });
      var key = await getToken();
      final dio = Dio();
      final response = await dio.request(
        'https://www.swiftnet.site/backend/api/orders/${widget.orderid}/details',
        options: Options(
          method: 'GET',
          headers: {'Authorization': 'Bearer $key'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        setState(() {
          orderid = data["orderId"];
        });

        // Pickup location
        final pickup = data["pickupLocation"];
        LatLng pickupLatLng = LatLng(pickup["latitude"], pickup["longitude"]);

        // Dropoff location
        final dropoff = data["dropoffLocation"];
        LatLng dropoffLatLng = LatLng(
          dropoff["latitude"],
          dropoff["longitude"],
        );

        // Driver location
        final driverLoc = data["driver"]["currentLocation"];
        LatLng driverLatLng = LatLng(
          driverLoc["latitude"],
          driverLoc["longitude"],
        );

        // Now you can assign them like this:
        LatLng start = driverLatLng; // driver location
        LatLng end = dropoffLatLng; // order dropoff

        final status = data["status"];

        if (status == "pending") {
          setState(() {
            this.start = driverLatLng;
            this.end = pickupLatLng;
          });
        } else if (status == "transit") {
          setState(() {
            this.start = driverLatLng;
            this.end = dropoffLatLng;
          });
        }

        fetchRoute();

        // You can now use start/end in a Polyline or Marker
      } else {
        //print(response.statusMessage);
        FlutterLogs.logError("TRACKER", "fetchorder1", response.statusMessage!);
      }
    } catch (e) {
      //print('Error fetching order details: $e');
      FlutterLogs.logError("TRACKER", "fetchorder2", e.toString());
    }
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
        end = end;
        start = start!;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(end, 18.0);
      });

      setState(() {
        loading = false;
      });
      // 🔌 connect to WebSocket server
      wsService.connect("ws://209.126.8.100:8080/ws");

      // 👂 listen for backend messages
      wsService.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          final orderId = data["order_id"];
          final lat = data["lat"];
          final lng = data["lng"];

          if (orderId == orderid) {
            setState(() {
              end = LatLng(lat, lng);
            });

            updateRoutes(start.latitude, start.longitude, lat, lng);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(LatLng(lat, lng), 18.0);
            });

            //fetchRoute();
          }
        } catch (e) {
          print("Invalid WS message: $e");
        }
      });
    } else {
      //print("Failed to fetch route: ${response.body}");
      FlutterLogs.logError("TRACKER", "fetchroute", response.body);
      setState(() {
        loading = false;
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
      setState(() {
        end = LatLng(endlat, endlng);
      });
    } else {
      print("Failed to fetch route: ${response.body}");
    }
  }

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(
      "pk.eyJ1Ijoia2lva28xMjEiLCJhIjoiY21la2FxMG8wMDViYjJrcXZ3MWFmd2ZvZSJ9.3FCWY9P2G8ZKrmLG1XZWcw",
    );
    getToken();
    // _getCurrentLocation()
    //     .then((position) {
    //       setState(() {
    //         start = LatLng(position.latitude, position.longitude);
    //         // For demonstration, let's set the end point a bit north-east of the start
    //         end = LatLng(position.latitude + 0.01, position.longitude + 0.01);
    //         routePoints = [start, end];
    //       });
    //     })
    //     .catchError((e) {
    //       print("Error getting location: $e");
    //     });

    getOrderDetails();
  }

  @override
  void dispose() {
    wsService.disconnect();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
  this.mapboxMap = mapboxMap;

  // Managers
  pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
  lineManager = await mapboxMap.annotations.createPolylineAnnotationManager(); // ✅ add this line

  // Load icons
  final ByteData bytes = await rootBundle.load("assets/images/bike.png");
  final ByteData bytes2 = await rootBundle.load("assets/images/box.png");

  final Uint8List imageData = bytes.buffer.asUint8List();
  final Uint8List imageData2 = bytes2.buffer.asUint8List();

  // Add two markers
  await pointAnnotationManager?.create(PointAnnotationOptions(
    geometry: Point(coordinates: Position(start.longitude, start.latitude)),
    image: imageData,
    iconSize: 0.3,
  ));

  await pointAnnotationManager?.create(PointAnnotationOptions(
    geometry: Point(coordinates: Position(end.longitude, end.latitude)),
    image: imageData2,
    iconSize: 0.3,
  ));

  // 🛣️ draw the route
  await _drawRoute();
}


  Future<void> _drawRoute() async {
  const orsApiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjZjNGY5M2ViNzJkMTQ1ODhiZGU1MDNjNjRlMjQxOTk3IiwiaCI6Im11cm11cjY0In0=";

  final url =
      "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}";
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) return;

  final data = jsonDecode(response.body);
  final coords = data["features"][0]["geometry"]["coordinates"] as List;

  // Convert route coordinates to GeoJSON LineString
  final geojson = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": coords,
        },
        "properties": {}
      }
    ]
  };

  // Add GeoJSON source to map
  await mapboxMap.style.addSource(GeoJsonSource(
    id: "route-source",
    data: jsonEncode(geojson),
  ));

  // Add styled route layer
  await mapboxMap.style.addLayer(LineLayer(
    id: "route-layer",
    sourceId: "route-source",
    lineJoin: LineJoin.ROUND,
    lineCap: LineCap.ROUND,
    lineBorderColor: Colors.black.value,
    lineBorderWidthExpression: [
      'interpolate',
      ['exponential', 1.5],
      ['zoom'],
      9.0,
      1.0,
      16.0,
      3.0,
    ],
    lineWidthExpression: [
      'interpolate',
      ['exponential', 1.5],
      ['zoom'],
      4.0,
      4.0,
      10.0,
      6.0,
      13.0,
      8.0,
      16.0,
      10.0,
      19.0,
      12.0,
      22.0,
      18.0,
    ],
    lineColorExpression: [
      'interpolate',
      ['linear'],
      ['zoom'],
      8.0,
      'rgb(51, 102, 255)',
      11.0,
      [
        'coalesce',
        ['get', 'route-color'],
        'rgb(51, 102, 255)',
      ],
    ],
  ));

  // Center map on route end
  await mapboxMap.flyTo(
    CameraOptions(
      center: Point(coordinates: Position(end.longitude, end.latitude)),
      zoom: 14.5,
    ),
    MapAnimationOptions(duration: 2000, startDelay: 0),
  );
}


  @override
  Widget build(BuildContext context) {
    CameraOptions camera = CameraOptions(
      center: Point(coordinates: Position(start.longitude, start.latitude)),
      zoom: 15,
      bearing: 20,
      pitch: 20,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Order Tracker",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: loading
          ? Container(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(color: Colors.deepOrange[700]),
              ),
            )
          : Stack(
              children: [
                MapWidget(cameraOptions: camera, onMapCreated: _onMapCreated),
              ],
            ),
    );
  }
}
