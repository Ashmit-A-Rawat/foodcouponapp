// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class ApiService {
  static final String baseUrl =
      dotenv.env['BASE_URL'] ?? 'http://10.140.215.235:5001';

  static GlobalKey<NavigatorState>? navigatorKey;

  // ==================== TOKEN MANAGEMENT ====================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // FIX: backend returns _id (MongoDB ObjectId), not id
  Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'userId', user['_id']?.toString() ?? user['id']?.toString() ?? '');
    await prefs.setString('username', user['username']?.toString() ?? '');
    await prefs.setString('name', user['name']?.toString() ?? '');
    await prefs.setString('role', user['role']?.toString() ?? '');
  }

  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId') ?? '',
      'username': prefs.getString('username') ?? '',
      'name': prefs.getString('name') ?? '',
      'role': prefs.getString('role') ?? '',
    };
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _handleUnauthorized() async {
    await clearData();
    navigatorKey?.currentState
        ?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response,
      {bool checkAuth = true}) async {
    if (checkAuth && response.statusCode == 401) {
      await _handleUnauthorized();
      return {
        'success': false,
        'message': 'Session expired. Please login again.'
      };
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response'};
    }
  }

  // ==================== AUTHENTICATION ====================
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'username': username, 'password': password, 'name': name}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        await saveToken(data['token']);
        await saveUserData(data['user']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await saveToken(data['token']);
        await saveUserData(data['user']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = await getHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/api/auth/me'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== WALLET & PAYMENTS ====================
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/payment/balance'),
          headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> makePayment({
    required double amount,
    String? description,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/payment/pay'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'description': description ?? 'QR Code Payment',
        }),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getTransactions() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/payment/transactions'),
          headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== RAZORPAY INTEGRATION ====================
  Future<Map<String, dynamic>> createRazorpayOrder(
      {required double amount}) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/razorpay/create-order'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required double amount,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/razorpay/verify-payment'),
        headers: headers,
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'amount': amount,
        }),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getRazorpayPaymentHistory() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/razorpay/payment-history'),
          headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== MENU MANAGEMENT ====================
  Future<Map<String, dynamic>> getMenuItems({String? category}) async {
    try {
      String url = '$baseUrl/api/menu';
      if (category != null && category != 'all') url += '?category=$category';
      final headers = await getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMenuItem(String itemId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/menu/$itemId'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // NOTE: /canteen/my-menu must be registered BEFORE /:id in menuRoutes.js
  Future<Map<String, dynamic>> getCanteenMenu() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/menu/canteen/my-menu'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createMenuItem({
    required String name,
    required String description,
    required double price,
    required String category,
    required int preparationTime,
    String? availableFrom,
    String? availableTo,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/menu'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'preparationTime': preparationTime,
          if (availableFrom != null) 'availableFrom': availableFrom,
          if (availableTo != null) 'availableTo': availableTo,
        }),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMenuItem({
    required String itemId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? preparationTime,
    bool? isAvailable,
    String? availableFrom,
    String? availableTo,
  }) async {
    try {
      final headers = await getHeaders();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (price != null) body['price'] = price;
      if (category != null) body['category'] = category;
      if (preparationTime != null) body['preparationTime'] = preparationTime;
      if (isAvailable != null) body['isAvailable'] = isAvailable;
      if (availableFrom != null) body['availableFrom'] = availableFrom;
      if (availableTo != null) body['availableTo'] = availableTo;
      final response = await http.put(
        Uri.parse('$baseUrl/api/menu/$itemId'),
        headers: headers,
        body: jsonEncode(body),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> toggleMenuItemAvailability(
      String itemId) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
          Uri.parse('$baseUrl/api/menu/$itemId/toggle'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMenuItem(String itemId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
          Uri.parse('$baseUrl/api/menu/$itemId'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== ORDER MANAGEMENT ====================
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    DateTime? requestedTime,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final headers = await getHeaders();
      final body = <String, dynamic>{
        'items': items,
        'paymentMethod': paymentMethod,
      };
      if (requestedTime != null)
        body['requestedTime'] = requestedTime.toIso8601String();
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: headers,
        body: jsonEncode(body),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/orders/my-orders'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/orders/$orderId'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
          Uri.parse('$baseUrl/api/orders/$orderId/cancel'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getCanteenOrders({
    String? status,
    String? date,
  }) async {
    try {
      String url = '$baseUrl/api/orders/canteen/all';
      final params = <String>[];
      if (status != null) params.add('status=$status');
      if (date != null) params.add('date=$date');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      final headers = await getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    DateTime? actualReadyTime,
  }) async {
    try {
      final headers = await getHeaders();
      final body = <String, dynamic>{'status': status};
      if (actualReadyTime != null)
        body['actualReadyTime'] = actualReadyTime.toIso8601String();
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/status'),
        headers: headers,
        body: jsonEncode(body),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyQRAndCompleteOrder(
      String qrToken) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/verify-qr'),
        headers: headers,
        body: jsonEncode({'qrToken': qrToken}),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== ADMIN FUNCTIONS ====================
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/payment/users'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> setBalance({
    required String userId,
    required double amount,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/payment/set-balance/$userId'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getBalanceSummaries() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/admin/balance-summaries'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getBalanceSummaryByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/admin/balance-summary/$year/$month'),
          headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> triggerBalanceReset() async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
          Uri.parse('$baseUrl/api/admin/reset-balances'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/admin/statistics'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String name,
    String? role,
    double? balance,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/create-user'),
        headers: headers,
        body: jsonEncode({
          'username': username,
          'password': password,
          'name': name,
          if (role != null) 'role': role,
          if (balance != null) 'balance': balance,
        }),
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== CANTEEN REPORTING ====================
  Future<Map<String, dynamic>> getCanteenDashboardStats() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/canteen/dashboard'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getCanteenTransactions() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/canteen/transactions'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getCanteenTransactionsByDate(
      String date) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/canteen/transactions/date/$date'),
          headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getCanteenTransactionsByMonth(
      int year, int month) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/api/canteen/transactions/month/$year/$month'),
          headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> exportCanteenToExcel({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/api/canteen/export/excel';
      final params = <String>[];
      if (startDate != null)
        params.add(
            'startDate=${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}');
      if (endDate != null)
        params.add(
            'endDate=${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return {'success': false, 'message': 'Session expired.'};
      }
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains(
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') ||
            contentType.contains('application/octet-stream')) {
          final dir = Platform.isAndroid
              ? await getExternalStorageDirectory()
              : await getApplicationDocumentsDirectory();
          final fileName =
              'Canteen_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final filePath = '${dir!.path}/$fileName';
          await File(filePath).writeAsBytes(response.bodyBytes);
          return {
            'success': true,
            'message': 'Excel downloaded',
            'filePath': filePath,
            'fileName': fileName
          };
        }
        return jsonDecode(response.body);
      }
      return {
        'success': false,
        'message': 'Export failed (${response.statusCode})'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> exportCanteenToPDF({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/api/canteen/export/pdf';
      final params = <String>[];
      if (startDate != null)
        params.add(
            'startDate=${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}');
      if (endDate != null)
        params.add(
            'endDate=${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return {'success': false, 'message': 'Session expired.'};
      }
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/pdf') ||
            contentType.contains('application/octet-stream')) {
          final dir = Platform.isAndroid
              ? await getExternalStorageDirectory()
              : await getApplicationDocumentsDirectory();
          final fileName =
              'Canteen_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final filePath = '${dir!.path}/$fileName';
          await File(filePath).writeAsBytes(response.bodyBytes);
          return {
            'success': true,
            'message': 'PDF downloaded',
            'filePath': filePath,
            'fileName': fileName
          };
        }
        return jsonDecode(response.body);
      }
      return {
        'success': false,
        'message': 'Export failed (${response.statusCode})'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}