import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/payment_service.dart';
import '../payment_success/payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Appointment appointment;

  const PaymentScreen({Key? key, required this.appointment}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Timer? _statusCheckTimer;
  final PaymentService _paymentService = PaymentService.to;
  bool _isLoading = true;
  String? _paymentUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Initialize payment
      final paymentUrl = await _paymentService.initializePayment(
        amount: widget.appointment.amount,
        currency: 'KES',
        description:
            'Appointment with Dr. ${widget.appointment.doctorName} on ${DateFormat('MMM d, y').format(widget.appointment.dateTime)}',
        email: user.email!,
      );

      setState(() {
        _paymentUrl = paymentUrl;
        _isLoading = false;
      });

      // Start checking payment status
      _startPaymentStatusCheck();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startPaymentStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final status = await _paymentService.checkPaymentStatus(
          appointmentId: widget.appointment.id,
        );

        if (status == 'completed') {
          timer.cancel();
          Get.off(() => PaymentSuccessScreen(appointment: widget.appointment));
        }
      } catch (e) {
        print('Error checking payment status: $e');
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _initializePayment();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_paymentUrl != null) {
      return WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(_paymentUrl!)),
      );
    }

    return const Center(
      child: Text('Something went wrong'),
    );
  }
}
