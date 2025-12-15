import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:choice/choice.dart';
import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
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
import 'package:swift/main.dart';
import 'package:swift/pages/homepage.dart';
import 'package:swift/pages/match.dart';
import 'package:swift/pages/payments.dart';
import 'package:swift/pages/tracker.dart';
import 'package:swift/services/nominatimservice.dart';
import 'package:swift/services/photon_service.dart';
import 'package:swift/services/websocketserviceasync.dart';

class SendPage extends StatefulWidget {
  final String? location;
  final bool? throughpass;
  final LatLng? destiny;

  const SendPage({Key? key, this.location, this.throughpass, this.destiny})
    : super(key: key);

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage>
    with SingleTickerProviderStateMixin {
  //final wsService = WebSocketService();
  final PhotonService _photonService = PhotonService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  var location = LatLng(0, 0);
  var destination = LatLng(0, 0);
  var loading = false;
  var token = "";
  var userid = "";
  bool fareloading = false;
  bool calculatedfare = false;
  var orderid = "";
  var driverid = "";

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

  // Payment tracking
  String paymentMethod = "";
  String paymentReference = "";

  // Location editing mode
  bool isEditingPickupLocation = false;

  final locationController = TextEditingController();
  final destinationController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final descriptionController = TextEditingController();
  final mpesaphoneController = PhoneController();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _pickupSearchController = TextEditingController();

  bool _isLoading = true;
  bool _kunaPending = false;
  final Dio dio = Dio();

  late WebSocketService wsService;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    getLocation();

    if (widget.throughpass == true) {
      setState(() {
        destinationController.text = widget.location!;
        _controller.text = widget.location!;
        destination = widget.destiny!;
      });
    }
    checkgates();

    wsService = WebSocketService();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _animationController.dispose();
    wsService.disconnect();
    super.dispose();
  }

  void _connectWebSocket() async {
    try {
      await wsService.connect("ws://185.196.20.88:8001/ws");
      print("WebSocket connected");
    } catch (e) {
      // Optionally, add some retry logic here or user feedback
      print("WebSocket connection failed: $e");
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token")!;
      userid = prefs.getString("user_id")!;
    });
    return prefs.getString("token");
  }

  Future<String?> getAddressFromLatLng(double lat, double lon) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1",
    );

    final response = await http.get(
      url,
      headers: {"User-Agent": "flutter_app"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["display_name"];
    } else {
      print("Error: ${response.statusCode}");
      return null;
    }
  }

  Future<Position> _getCurrentLocation() async {
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
      "demand_factor,omitempty": 1.0,
      "average_speed_kmph,omitempty": 80,
    });
    var dio = Dio();
    var response = await dio.request(
      'https://www.swiftnet.site/backend/api/fare/calculate',
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

  Future<void> refund() async {
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
      "reference": paymentReference,
      "amount": fare * 100,
    });
    var dio = Dio();
    var response = await dio.request(
      'https://www.swiftnet.site/backend/api/payment/refund',
      options: Options(method: 'POST', headers: headers),
      data: data,
    );

    if (response.statusCode == 200) {

    } else {
      print(response.statusMessage);

    }
  }

  Future<void> createOrder() async {
    setState(() {
      _isLoading = true;
    });

    var key = await getToken();

    var headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${key}',
    };
    var data = json.encode({
      "userId": int.parse(userid),
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
      "paymentMethod": paymentMethod,
      "paymentReference": paymentReference,
      "fare": fare,
    });

    var dio = Dio();
    var response = await dio.request(
      'https://www.swiftnet.site/backend/api/orders/create',
      options: Options(method: 'POST', headers: headers),
      data: data,
    );

    if (response.statusCode == 201) {
      print(json.encode(response.data["order"]["orderId"]));
      setState(() {
        _isLoading = false;
      });

      saveTracking();

      var orderid = response.data["order"]["orderId"];

      setState(() {
        this.orderid = orderid.toString();
        promt = true;
      });

      // Now match the driver
      match();
    } else {
      print(response.statusMessage);
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text("Failed to create order. Please try again."),
        ),
      );
    }
  }

  Future<void> match() async {
    try{
      print("Matching driver for order ID: $orderid");
      print("------------------------------------------------------00000");
      setState(() {
        fareloading = true;
        _isLoading = true;
      });
      var key = await getToken();
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ${key}',
      };
      var data = {'orderId': orderid, 'fare': fare};
      var dio = Dio();
      var response = await dio.request(
        'https://www.swiftnet.site/backend/api/orders/match-driver',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      if (response.statusCode == 200) {
        print(json.encode(response.data));
        print("------------------------------------------------------00001");
        try {
          setState(() {
            driverphone = response.data["userPhone"];
            drivername = response.data["userName"];
            licenseplate = response.data["licensePlate"];
            driverfound = true;
            promt = true;
            fareloading = false;
            _isLoading = false;
          });

          var receivedDriverId = response.data["driverId"];

          setState(() {
            this.driverid = receivedDriverId
                .toString(); // Update the class-level variable
          });

          final userrequest = jsonEncode({
            "driverId": this.driverid, // Use the class-level variable
            "orderId": orderid,
            "type": "new_order",
            "pickupLatitude": location.latitude,
            "pickupLongitude": location.longitude,
            "destinationLatitude": destination.latitude,
            "destinationLongitude": destination.longitude,
          });

          wsService.send(userrequest);
        } catch (e, stack) {
          print(
            "------------------------------------------------------0000shida",
          );
          print('some error: $e');
          print(stack);
        }

        _showDriverFoundDialog();
      } else if (response.statusCode == 204) {
        print("------------------------------------------------------0000nodrivers");
        setState(() {
          fareloading = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            content: Text("Failed to match driver. Please try again."),
          ),
        );

        refund();
      } else {
        print("------------------------------------------------------00003");
        print(response.statusMessage);
        setState(() {
          fareloading = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text("Failed to match driver. Please try again."),
          ),
        );
      }
    }catch(e){
      setState(() {
        fareloading = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          content: Text("Failed to match driver. Please try again." ),
        ),
      );
    }
  }

  void _showDriverFoundDialog() {
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.success,
      dialogBackgroundColor: Colors.white,
      btnOkColor: Colors.deepOrange[700],
      body: Center(
        child: Container(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade400,
                                  Colors.deepOrange.shade600,
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Image.asset(
                                "assets/images/driver.png",
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drivername,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "4.8",
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              licenseplate,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_bike,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Rider is on the way!",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: 'This is Ignored',
      desc: 'This is also Ignored',
      btnOkOnPress: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => ),
        // );

        print("-------------------------nnnn");
        print(orderid);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Tracker(orderid: orderid), // Replace with your detail page
          ),
        );
      },
    ).show();
  }

  Future<void> checkgates() async {
    var key = await getToken();
    var headers = {'Authorization': "Bearer ${key}"};

    try {
      var response = await dio.request(
        'https://www.swiftnet.site/backend/api/orders/pending?page=0',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        setState(() {
          var data = response.data as List;
          if (data.length > 0) {
            setState(() {
              _isLoading = false;
              _kunaPending = false;
            });
          } else {
            setState(() {
              _kunaPending = false;
              _isLoading = false;
            });
          }
        });
      } else {
        setState(() {
          _kunaPending = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _kunaPending = false;
        _isLoading = false;
      });
    }
  }

  @Preview(name: "FareConfirmation")
  void showFareConfirmationDialog() {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade50, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Column(
                      children: [
                        // _buildFareRow(
                        //   "Distance",
                        //   "${distance_km.toString()} Km",
                        //   fareloading,
                        // ),
                        // Divider(height: 20),
                        // _buildFareRow("Commission", "0.15%", fareloading),
                        // Divider(height: 20),
                        _buildFareRow(
                          "Fare",
                          "${NumberFormat().format(fare)} Ksh",
                          fareloading,
                          highlight: true,
                        ),
                        Divider(height: 20),
                        _buildFareRow(
                          "Payment Method",
                          selectedValue ?? "Not selected",
                          false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      title: 'This is Ignored',
      desc: 'This is also Ignored',
      btnOkOnPress: () {
        // User accepted the fare, now process payment
        processPayment();
      },
    ).show();
  }

  void processPayment() {
    if (selectedValue == "Online") {
      var ref = paymentReference = generateRef();
      FlutterPaystackPlus.openPaystackPopup(
        context: context,
        secretKey: "sk_test_b24253c87dfd841bdc86edbefb243622b8e59422",
        currency: "KES",
        customerEmail: "toobafah40@gmail.com",
        amount: (fare * 100).toString(),
        reference: ref,
        onClosed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text("Payment cancelled"),
            ),
          );
        },
        onSuccess: () {
          setState(() {
            paymentMethod = "Mpesa";
            paymentReference = ref;
          });
          createOrder();
        },
      );
    } else if (selectedValue == "Cash") {
      setState(() {
        paymentMethod = "Cash";
        paymentReference = "CASH-${generateRef()}";
      });
      createOrder();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text("Please select a payment method"),
        ),
      );
    }
  }

  void fetchAddress(Lat, Lng) async {
    final address = await getAddressFromLatLng(Lat, Lng);
    setState(() {
      locationController.text = address!;
    });
  }

  void getLocation() async {
    setState(() {
      loading = true;
    });
    Position position = await _getCurrentLocation();
    fetchAddress(position.latitude, position.longitude);
    setState(() {
      location = LatLng(position.latitude, position.longitude);
      loading = false;
    });
  }

  void _showMapPicker(bool isPickup) async {
    final selectedLocation = await showDialog<LatLng>(
      context: context,
      builder: (context) =>
          MapPickerDialog(initialLocation: isPickup ? location : destination),
    );

    if (selectedLocation != null) {
      if (isPickup) {
        setState(() {
          location = selectedLocation;
          loading = true;
        });
        final address = await getAddressFromLatLng(
          selectedLocation.latitude,
          selectedLocation.longitude,
        );
        setState(() {
          locationController.text = address ?? "";
          loading = false;
        });
      } else {
        setState(() {
          destination = selectedLocation;
        });
        final address = await getAddressFromLatLng(
          selectedLocation.latitude,
          selectedLocation.longitude,
        );
        setState(() {
          destinationController.text = address ?? "";
          _controller.text = address ?? "";
        });
      }
    }
  }

  List<String> choices = ['Online', 'Cash'];
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
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Delivery",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Location data", Colors.blue),
              Divider(),
              SizedBox(height: 10),
              _buildLocationCard(),
              SizedBox(height: 20),
              _buildSectionHeader("Receiver data", Colors.blue),
              Divider(),
              SizedBox(height: 10),
              _buildReceiverCard(),
              SizedBox(height: 20),
              _buildSectionHeader("Payment data", Colors.blue),
              Divider(),
              _buildPaymentCard(),
              SizedBox(height: 40),
              _kunaPending
                  ? Center(
                      child: Text(
                        "Cannot proceed while orders still pending",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: Colors.deepOrangeAccent,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : _buildSubmitButton(),
              //_buildSubmitButton(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          if (isEditingPickupLocation)
            _buildPickupSearchBox()
          else
            _buildLocationField(
              controller: locationController,
              icon: Icons.my_location,
              iconColor: Colors.green,
              hint: "Pickup location",
              loading: loading,
              onTap: () {
                setState(() {
                  isEditingPickupLocation = true;
                });
              },
            ),

          if (isEditingPickupLocation) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.gps_fixed,
                    label: "Current",
                    color: Colors.green,
                    onPressed: () {
                      getLocation();
                      setState(() {
                        isEditingPickupLocation = false;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.map_outlined,
                    label: "Pin Map",
                    color: Colors.deepOrange,
                    onPressed: () => _showMapPicker(true),
                  ),
                ),
              ],
            ),
          ],

          //useless divider
          // SizedBox(height: 16),
          // Container(
          //   height: 2,
          //   margin: EdgeInsets.symmetric(horizontal: 40),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: Container(
          //           decoration: BoxDecoration(
          //             gradient: LinearGradient(
          //               colors: [Colors.orange, Colors.orange],
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          SizedBox(height: 16),

          destinationController.text.isEmpty
              ? _buildDestinationSearchBox()
              : Column(
                  children: [
                    _buildLocationField(
                      controller: destinationController,
                      icon: Icons.location_on,
                      iconColor: Colors.deepOrange,
                      hint: "Dropoff location",
                      onTap: () {
                        setState(() {
                          destinationController.clear();
                          _controller.clear();
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _showMapPicker(false),
                        child: Text(
                          "Adjust on Map",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrangeAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
    bool loading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          //border: Border.all(color: iconColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isEmpty ? hint : controller.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: controller.text.isEmpty
                      ? Colors.grey[500]
                      : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (loading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrangeAccent.shade200,
        foregroundColor: Colors.white,
        //side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPickupSearchBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.0)),
      ),
      child: TypeAheadField<Map<String, dynamic>>(
        direction: VerticalDirection.up,
        suggestionsCallback: (pattern) async {
          if (pattern.isEmpty) return [];
          return await _photonService.searchLocations(pattern);
        },
        itemBuilder: (context, suggestion) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[400], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion["displayName"],
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
        onSelected: (suggestion) {
          setState(() {
            locationController.text = suggestion["displayName"];
            _pickupSearchController.text = suggestion["displayName"];
            location = LatLng(
              double.tryParse(suggestion["lat"])!,
              double.tryParse(suggestion["lon"])!,
            );
            isEditingPickupLocation = false;
          });
        },
        builder: (context, controller, focusNode) {
          _pickupSearchController.value = controller.value;
          return TextField(
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: "Search pickup location...",
              hintStyle: GoogleFonts.inter(),
              border: InputBorder.none,
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search, color: Colors.green, size: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDestinationSearchBox() {
    return Container(
      //height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        //border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
      ),
      child: TypeAheadField<Map<String, dynamic>>(
        direction: VerticalDirection.up,
        suggestionsCallback: (pattern) async {
          if (pattern.isEmpty) return [];
          return await _photonService.searchLocations(pattern);
        },
        itemBuilder: (context, suggestion) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[400], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion["displayName"],
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
        onSelected: (suggestion) {
          setState(() {
            destinationController.text = suggestion["displayName"];
            _controller.text = suggestion["displayName"];

            destination = LatLng(
              double.tryParse(suggestion["lat"])!,
              double.tryParse(suggestion["lon"])!,
            );
          });

          print("destination_________________ " + destination.toString());
          print(destination);
        },
        builder: (context, controller, focusNode) {
          _controller.value = controller.value;
          return TextField(
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: "Search dropoff location...",
              hintStyle: GoogleFonts.inter(),
              border: InputBorder.none,
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search, color: Colors.deepOrange, size: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiverCard() {
    return Container(
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          _buildInputField(
            controller: nameController,
            hint: "Contact Name",
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            heightof: 50,
          ),
          SizedBox(height: 16),
          _buildInputField(
            controller: phoneController,
            hint: "Contact Phone",
            icon: Icons.phone_outlined,
            iconColor: Colors.blue,
            keyboardType: TextInputType.phone,
            heightof: 50,
          ),
          SizedBox(height: 16),
          _buildInputField(
            controller: descriptionController,
            hint: "Description (optional)",
            icon: Icons.notes_outlined,
            iconColor: Colors.blue,
            maxLines: 3,
            heightof: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required double heightof,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      height: heightof,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: maxLines > 1 ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        //border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          Row(
            children: choices.map((choice) {
              final isSelected = selectedValue == choice;
              final color = choice == "Online" ? Colors.purple : Colors.green;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: choice == choices.first ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => setSelectedValue(choice),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.1),
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            choice == "Online"
                                ? "assets/images/mpesa.png"
                                : "assets/images/cash.png",
                            height: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            choice,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? color : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.deepOrangeAccent,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _isLoading
            ? null
            : () {
                if (location.latitude.isNaN ||
                    destinationController.text.isEmpty ||
                    nameController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      content: Text("Please fill all required fields"),
                    ),
                  );
                } else if (selectedValue == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      content: Text("Please select a payment method"),
                    ),
                  );
                } else {
                  calculateFare().then((_) {
                    showFareConfirmationDialog();
                  });
                }
              },
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Next",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Skeletonizer(
            enabled: loading,
            child: Text(
              label,
              style: GoogleFonts.inter(
                decoration: TextDecoration.none,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: highlight ? Colors.black87 : Colors.grey[700],
              ),
            ),
          ),
          Skeletonizer(
            enabled: loading,
            child: Text(
              value,
              style: GoogleFonts.inter(
                decoration: TextDecoration.none,
                fontSize: highlight ? 20 : 15,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? Colors.deepOrange : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Map Picker Dialog Widget
class MapPickerDialog extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerDialog({Key? key, required this.initialLocation})
    : super(key: key);

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  late MapController mapController;
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
    mapController = MapController(
      initPosition: GeoPoint(
        latitude: widget.initialLocation.latitude,
        longitude: widget.initialLocation.longitude,
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.map, color: Colors.deepOrange, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Select Location",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Map
            Expanded(
              child: ClipRRect(
                child: Stack(
                  children: [
                    OSMFlutter(
                      controller: mapController,
                      osmOption: OSMOption(
                        zoomOption: ZoomOption(
                          initZoom: 15,
                          minZoomLevel: 3,
                          maxZoomLevel: 19,
                          stepZoom: 1.0,
                        ),
                        userLocationMarker: UserLocationMaker(
                          personMarker: MarkerIcon(
                            icon: Icon(
                              Icons.location_history_rounded,
                              color: Colors.red,
                              size: 48,
                            ),
                          ),
                          directionArrowMarker: MarkerIcon(
                            icon: Icon(Icons.double_arrow, size: 48),
                          ),
                        ),
                      ),
                      onMapIsReady: (isReady) async {
                        if (isReady) {
                          await mapController.addMarker(
                            GeoPoint(
                              latitude: selectedLocation.latitude,
                              longitude: selectedLocation.longitude,
                            ),
                            markerIcon: MarkerIcon(
                              icon: Icon(
                                Icons.location_pin,
                                color: Colors.deepOrange,
                                size: 56,
                              ),
                            ),
                          );
                        }
                      },
                      onGeoPointClicked: (geoPoint) async {
                        await mapController.removeMarker(
                          GeoPoint(
                            latitude: selectedLocation.latitude,
                            longitude: selectedLocation.longitude,
                          ),
                        );

                        setState(() {
                          selectedLocation = LatLng(
                            geoPoint.latitude,
                            geoPoint.longitude,
                          );
                        });

                        await mapController.addMarker(
                          geoPoint,
                          markerIcon: MarkerIcon(
                            icon: Icon(
                              Icons.location_pin,
                              color: Colors.deepOrange,
                              size: 56,
                            ),
                          ),
                        );
                      },
                    ),
                    // Animated pin indicator
                    Center(
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 600),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: 0.8 + (value * 0.2),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepOrange.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.deepOrange,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Instructions and Confirm Button
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.deepOrange,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Tap anywhere on the map to place a pin",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.deepOrange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27),
                      gradient: LinearGradient(
                        colors: [Colors.deepOrange, Colors.orange.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context, selectedLocation);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Confirm Location",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
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

String generateRef() {
  final randomCode = Random().nextInt(3234234);
  return 'ref-$randomCode';
}
