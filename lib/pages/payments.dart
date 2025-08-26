import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

class Payments extends StatefulWidget {
  @override
  State<Payments> createState() => _PaymentsState();
}

class _PaymentsState extends State<Payments> {
  String generateRef() {
    final randomCode = Random().nextInt(3234234);
    return 'ref-$randomCode';
  }

  String _selectedRadioValue = 'mpesa';

  bool initializingPayment = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Payment",
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                child: Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Swift balance",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Ksh 0.00",
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              ListTile(
                title: Text("What is swift balance?"),
                leading: Icon(Icons.info_outline),
              ),

              ListTile(
                title: Text("see Bolt balance transactions"),
                leading: Icon(Icons.info_outline),
              ),

              Divider(),

              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    "Payment methods",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  ListTile(
                    title: Text(
                      'Mpesa',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    leading: Icon(Icons.wallet),
                    trailing: Radio<String>(
                      value: 'mpesa',
                      groupValue: _selectedRadioValue,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedRadioValue = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.money),
                    title: Text('Cash', style: GoogleFonts.inter(fontSize: 14)),
                    trailing: Radio<String>(
                      value: 'cash',
                      groupValue: _selectedRadioValue,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedRadioValue = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.credit_card),
                    title: Text('Card', style: GoogleFonts.inter(fontSize: 14)),
                    trailing: Radio<String>(
                      value: 'card',
                      groupValue: _selectedRadioValue,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedRadioValue = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
