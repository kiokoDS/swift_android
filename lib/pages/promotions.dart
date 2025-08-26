import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoPage extends StatefulWidget {
  @override
  _PromoPageState createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Promo Code',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter promo code',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200], // background color
                borderRadius: BorderRadius.circular(10), // makes it rounded
              ),
              child: TextField(
                controller: _promoController,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.inter(fontSize: 14),
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Code",
                  border: InputBorder.none, // remove default TextField border
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.deepOrange[700],
                ),
                onPressed: () {
                  final promoCode = _promoController.text.trim();
                  if (promoCode.isNotEmpty) {
                    // TODO: Apply promo code to order
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Promo code applied')),
                    );
                  }
                },
                child: Text(
                  "Apply",
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
    );
  }
}
