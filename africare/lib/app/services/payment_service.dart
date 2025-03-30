import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  static PaymentService get to => _instance;

  static const String _baseUrl = 'https://sandbox.intasend.com/api/v1';
  static const String _publishableKey = 'YOUR_INTASEND_PUBLISHABLE_KEY';
  static const String _secretKey = 'YOUR_INTASEND_SECRET_KEY';

  Future<Map<String, dynamic>> createPaymentLink({
    required String amount,
    required String currency,
    required String description,
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment/collection'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_secretKey',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'description': description,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'method': ['card', 'mpesa'],
          'redirect_url': 'africare://payment-callback',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment link: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment service error: $e');
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String trackingId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment/status/$trackingId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment status check error: $e');
    }
  }

  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phone,
    required String amount,
    required String currency,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment/mpesa-stk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_secretKey',
        },
        body: jsonEncode({
          'phone': phone,
          'amount': amount,
          'currency': currency,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate M-Pesa payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('M-Pesa payment error: $e');
    }
  }

  Future<Map<String, dynamic>> refundPayment({
    required String trackingId,
    required String amount,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment/refund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_secretKey',
        },
        body: jsonEncode({
          'tracking_id': trackingId,
          'amount': amount,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to process refund: ${response.body}');
      }
    } catch (e) {
      throw Exception('Refund error: $e');
    }
  }
}
