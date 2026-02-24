// lib/services/razorpay_service.dart
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final ApiService _apiService = ApiService();
  final Function(bool success, String message, dynamic data) onPaymentComplete;

  RazorpayService({required this.onPaymentComplete}) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<void> openCheckout({
    required double amount,
    required String name,
    required String email,
    required String contact,
  }) async {
    try {
      // Create order on backend
      final orderResult = await _apiService.createRazorpayOrder(amount: amount);

      if (!orderResult['success']) {
        onPaymentComplete(false, orderResult['message'] ?? 'Failed to create order', null);
        return;
      }

      final options = {
        'key': orderResult['key'],
        'amount': (amount * 100).toInt(),
        'name': 'Metro Food',
        'description': 'Wallet Recharge',
        'order_id': orderResult['order']['id'],
        'prefill': {
          'contact': contact,
          'email': email,
          'name': name,
        },
        'theme': {
          'color': '#6366F1',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      onPaymentComplete(false, 'Error opening payment: $e', null);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // You need to store the amount somewhere or pass it
    // For now, we'll use a default amount - you should modify this
    double amount = 0; // This should come from your state
    
    // Verify payment on backend
    final result = await _apiService.verifyRazorpayPayment(
      orderId: response.orderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
      amount: amount, // Add this parameter
    );

    if (result['success']) {
      onPaymentComplete(true, 'Payment successful!', result);
    } else {
      onPaymentComplete(false, result['message'] ?? 'Payment verification failed', null);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onPaymentComplete(false, 'Payment failed: ${response.message}', null);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onPaymentComplete(false, 'External wallet selected', null);
  }
}