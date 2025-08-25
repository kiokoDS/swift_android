import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift/pages/accountpage.dart';
import 'package:swift/pages/homepage.dart';
import 'package:swift/pages/orderspage.dart';

class Indexpage extends StatefulWidget {
  @override
  State<Indexpage> createState() => _IndexAppState();
}

class _IndexAppState extends State<Indexpage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [HomePage(), OrdersPage(), AccountPage()];

  var username = "";
  var token = "";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString("token")!;
      username = prefs.getString("username")!;
    });
    return prefs.getString("token");
  }

  @override
  void initState() {
    super.initState();
    getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Swift App")),
      drawer: Drawer(
        backgroundColor: Colors.white,
        shape: null,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.start,
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Icon(Icons.person),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: GoogleFonts.hindSiliguri(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "my account",
                            style: GoogleFonts.hindSiliguri(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Row(
                      children: [
                        Icon(FeatherIcons.star, size: 10),
                        Text(
                          "  5.0",
                          style: GoogleFonts.hindSiliguri(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          " rating",
                          style: GoogleFonts.hindSiliguri(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(FeatherIcons.creditCard, size: 20),
              title: Text(
                "Payments",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(FeatherIcons.tag, size: 20),
              title: Text(
                "Promotions",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(FeatherIcons.activity, size: 20),
              title: Text(
                "My Rides",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(FeatherIcons.shield, size: 20),
              title: Text(
                "Safety",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(FeatherIcons.dollarSign, size: 20),
              title: Text(
                "Expenses",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(FeatherIcons.phoneCall, size: 20),
              title: Text(
                "Support",
                style: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.w600 ),
              ),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(FeatherIcons.info, size: 20),
              title: Text(
                "About",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        iconSize: 20,
        selectedLabelStyle: GoogleFonts.hindSiliguri(
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: GoogleFonts.hindSiliguri(
          fontWeight: FontWeight.w700,
        ),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(FeatherIcons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.package),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.user),
            label: "Account",
          ),
        ],
      ),
    );
  }
}
