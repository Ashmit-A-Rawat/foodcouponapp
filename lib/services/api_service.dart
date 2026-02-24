// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class ApiService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.140.215.235:5001';

  // Navigation key for global navigation
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

  Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user['id']);
    await prefs.setString('username', user['username']);
    await prefs.setString('name', user['name']);
    await prefs.setString('role', user['role']);
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

  // Handle 401 Unauthorized - Clear token and navigate to login
  Future<void> _handleUnauthorized() async {
    await clearData();
    if (navigatorKey?.currentContext != null) {
      navigatorKey!.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  // Check response for 401 and handle it
  Future<Map<String, dynamic>> _handleResponse(http.Response response,
      {bool checkAuth = true}) async {
    if (checkAuth && response.statusCode == 401) {
      await _handleUnauthorized();
      return {
        'success': false,
        'message': 'Session expired. Please login again.'
      };
    }
    return jsonDecode(response.body);
  }

  // ==================== AUTHENTICATION ====================
  // Register
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'name': name,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        await saveToken(data['token']);
        await saveUserData(data['user']);
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await saveToken(data['token']);
        await saveUserData(data['user']);
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get current user
  Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== WALLET & PAYMENTS ====================
  // Get balance
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/balance'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Make payment
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

  // Get transactions
  Future<Map<String, dynamic>> getTransactions() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/transactions'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== RAZORPAY INTEGRATION ====================
  // Create Razorpay order
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

  // Verify Razorpay payment
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

  // Get Razorpay payment history
  Future<Map<String, dynamic>> getRazorpayPaymentHistory() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/razorpay/payment-history'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== MENU MANAGEMENT ====================
  // Get all menu items (for users)
  Future<Map<String, dynamic>> getMenuItems({String? category}) async {
    try {
      String url = '$baseUrl/api/menu';
      if (category != null && category != 'all') {
        url += '?category=$category';
      }
      final headers = await getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get single menu item
  Future<Map<String, dynamic>> getMenuItem(String itemId) async {
    try {
      final headers = await getHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/api/menu/$itemId'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get canteen's own menu (for canteen staff)
  Future<Map<String, dynamic>> getCanteenMenu() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/menu/canteen/my-menu'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create menu item (canteen only)
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

  // Update menu item (canteen only)
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

  // Toggle menu item availability (canteen only)
  Future<Map<String, dynamic>> toggleMenuItemAvailability(String itemId) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/menu/$itemId/toggle'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete menu item (canteen only)
  Future<Map<String, dynamic>> deleteMenuItem(String itemId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/menu/$itemId'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== ORDER MANAGEMENT ====================
  // Create new order
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    DateTime? requestedTime,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {
        'items': items,
        'paymentMethod': paymentMethod,
      };
      
      if (requestedTime != null) {
        body['requestedTime'] = requestedTime.toIso8601String();
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

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

  // Get user's orders
  Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/my-orders'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get single order
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Cancel order (user)
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/cancel'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get canteen orders (canteen only)
  Future<Map<String, dynamic>> getCanteenOrders({
    String? status,
    String? date,
  }) async {
    try {
      String url = '$baseUrl/api/orders/canteen/all';
      final queryParams = <String>[];
      if (status != null) queryParams.add('status=$status');
      if (date != null) queryParams.add('date=$date');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final headers = await getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update order status (canteen only)
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    DateTime? actualReadyTime,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {'status': status};
      if (actualReadyTime != null) {
        body['actualReadyTime'] = actualReadyTime.toIso8601String();
      }

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

  // Verify QR code and complete order (canteen only)
  Future<Map<String, dynamic>> verifyQRAndCompleteOrder(String qrToken) async {
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
  // Admin: Get all users
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/users'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin: Set user balance
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

  // Admin: Get all balance summaries
  Future<Map<String, dynamic>> getBalanceSummaries() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/balance-summaries'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin: Get balance summary by month/year
  Future<Map<String, dynamic>> getBalanceSummaryByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/balance-summary/$year/$month'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin: Manually trigger balance reset
  Future<Map<String, dynamic>> triggerBalanceReset() async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/reset-balances'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin: Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/statistics'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin: Create new user
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
  // Canteen: Get dashboard stats
  Future<Map<String, dynamic>> getCanteenDashboardStats() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/canteen/dashboard'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Canteen: Get all transactions
  Future<Map<String, dynamic>> getCanteenTransactions() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/canteen/transactions'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Canteen: Get transactions by date
  Future<Map<String, dynamic>> getCanteenTransactionsByDate(String date) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/canteen/transactions/date/$date'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Canteen: Get transactions by month
  Future<Map<String, dynamic>> getCanteenTransactionsByMonth(
      int year, int month) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/canteen/transactions/month/$year/$month'),
        headers: headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Canteen: Export to Excel with optional date filters
  Future<Map<String, dynamic>> exportCanteenToExcel({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await getHeaders();

      String url = '$baseUrl/api/canteen/export/excel';
      List<String> queryParams = [];

      if (startDate != null) {
        final dateStr =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        queryParams.add('startDate=$dateStr');
      }

      if (endDate != null) {
        final dateStr =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        queryParams.add('endDate=$dateStr');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return {
          'success': false,
          'message': 'Session expired. Please login again.'
        };
      }

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains(
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') ||
            contentType.contains('application/octet-stream')) {
          Directory? directory;
          if (Platform.isAndroid) {
            directory = await getExternalStorageDirectory();
          } else {
            directory = await getApplicationDocumentsDirectory();
          }

          final fileName =
              'Canteen_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final filePath = '${directory!.path}/$fileName';

          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          return {
            'success': true,
            'message': 'Excel file downloaded successfully',
            'filePath': filePath,
            'fileName': fileName
          };
        } else {
          return jsonDecode(response.body);
        }
      } else {
        return {
          'success': false,
          'message': 'Export failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Canteen: Export to PDF with optional date filters
  Future<Map<String, dynamic>> exportCanteenToPDF({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await getHeaders();

      String url = '$baseUrl/api/canteen/export/pdf';
      List<String> queryParams = [];

      if (startDate != null) {
        final dateStr =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        queryParams.add('startDate=$dateStr');
      }

      if (endDate != null) {
        final dateStr =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        queryParams.add('endDate=$dateStr');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return {
          'success': false,
          'message': 'Session expired. Please login again.'
        };
      }

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/pdf') ||
            contentType.contains('application/octet-stream')) {
          Directory? directory;
          if (Platform.isAndroid) {
            directory = await getExternalStorageDirectory();
          } else {
            directory = await getApplicationDocumentsDirectory();
          }

          final fileName =
              'Canteen_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final filePath = '${directory!.path}/$fileName';

          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          return {
            'success': true,
            'message': 'PDF file downloaded successfully',
            'filePath': filePath,
            'fileName': fileName
          };
        } else {
          return jsonDecode(response.body);
        }
      } else {
        return {
          'success': false,
          'message': 'Export failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}