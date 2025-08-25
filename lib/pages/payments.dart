import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
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

  bool initializingPayment = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Center(
          child: initializingPayment
              ? const CircularProgressIndicator.adaptive()
              //
              : OutlinedButton(
                  onPressed: () async {
                    final ref = generateRef();
                    final amount = int.parse("15");
                    try {
                      return await FlutterPaystackPlus.openPaystackPopup(
                        publicKey:
                            "pk_test_5a22f3b8d015035fce3890c86740410777267c32",
                        context: context,
                        secretKey:
                            "sk_test_b24253c87dfd841bdc86edbefb243622b8e59422",
                        currency: 'KES',
                        customerEmail: "test@gmail.com",
                        amount: (amount * 100).toString(),
                        reference: ref,
                        callBackUrl: "[GET IT FROM YOUR PAYSTACK DASHBOARD]",
                        onClosed: () {
                          debugPrint('Could\'nt finish payment');
                        },
                        onSuccess: () {
                          debugPrint('Payment successful');
                        },
                      );
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                  child: const Text('Make Payment'),
                ),
        ),
      ),
    );
  }

  void makePayment() async {
    const secretKey = 'sk_test_b24253c87dfd841bdc86edbefb243622b8e59422';

    final request = PaystackTransactionRequest(
      reference: 'ps_${DateTime.now().microsecondsSinceEpoch}',
      secretKey: secretKey,
      email: 'test@gmail.com',
      amount: 1.5 * 100,
      currency: PaystackCurrency.kes,
      channel: [PaystackPaymentChannel.card],
    );

    setState(() => initializingPayment = true);
    final initializedTransaction = await PaymentService.initializeTransaction(
      request,
    );

    if (!mounted) return;
    setState(() => initializingPayment = false);

    if (!initializedTransaction.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(initializedTransaction.message),
        ),
      );

      return;
    }

    await PaymentService.showPaymentModal(
      context,
      transaction: initializedTransaction,
      // Callback URL must match the one specified on your paystack dashboard,
      callbackUrl: 'https://webhook-test.com/9a5794bbd5840615f6ae89f707528583',
    );

    final response = await PaymentService.verifyTransaction(
      paystackSecretKey: secretKey,
      initializedTransaction.data?.reference ?? request.reference,
    );

    Logger().i(response.toMap());
  }
}
