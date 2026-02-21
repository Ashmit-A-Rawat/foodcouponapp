import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class ApiService {

  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.140.215.235:5001';// Change port if different

  // Navigation key for global navigation
  static GlobalKey<NavigatorState>? navigatorKey;

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

    print(navigatorKey?.currentContext);
    if (navigatorKey?.currentContext != null) {
      // Pop all routes and navigate to login
      navigatorKey!.currentState?.pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    }
  }

  // Check response for 401 and handle it
  Future<Map<String, dynamic>> _handleResponse(http.Response response, {bool checkAuth = true}) async {
    if (checkAuth && response.statusCode == 401) {
      await _handleUnauthorized();
      return {'success': false, 'message': 'Session expired. Please login again.'};
    }

    return jsonDecode(response.body);
  }

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
      print(baseUrl);
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
  Future<Map<String, dynamic>> getCanteenTransactionsByMonth(int year, int month) async {
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

      // Build URL with query parameters
      String url = '$baseUrl/api/canteen/export/excel';
      List<String> queryParams = [];

      if (startDate != null) {
        final dateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        queryParams.add('startDate=$dateStr');
      }

      if (endDate != null) {
        final dateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        queryParams.add('endDate=$dateStr');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('Excel Export URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Excel Export Status Code: ${response.statusCode}');

      // Check for 401 before processing file
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return {'success': false, 'message': 'Session expired. Please login again.'};
      }

      if (response.statusCode == 200) {
        // Check content type
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') ||
            contentType.contains('application/octet-stream')) {

          // Get downloads directory
          Directory? directory;
          if (Platform.isAndroid) {
            directory = await getExternalStorageDirectory();
          } else {
            directory = await getApplicationDocumentsDirectory();
          }

          // Create file path
          final fileName = 'Canteen_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final filePath = '${directory!.path}/$fileName';

          // Save file
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          print('Excel file saved at: $filePath');

          return {
            'success': true,
            'message': 'Excel file downloaded successfully',
            'filePath': filePath,
            'fileName': fileName
          };
        } else {
          // It's JSON error
          return jsonDecode(response.body);
        }
      } else {
        return {
          'success': false,
          'message': 'Export failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Excel Export Error: $e');
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

      // Build URL with query parameters
      String url = '$baseUrl/api/canteen/export/pdf';
      List<String> queryParams = [];

      if (startDate != null) {
        final dateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        queryParams.add('startDate=$dateStr');
      }

      if (endDate != null) {
        final dateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        queryParams.add('endDate=$dateStr');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('PDF Export URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('PDF Export Status Code: ${response.statusCode}');

      // Check for 401 before processing file
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return {'success': false, 'message': 'Session expired. Please login again.'};
      }

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/pdf') ||
            contentType.contains('application/octet-stream')) {

          // Get downloads directory
          Directory? directory;
          if (Platform.isAndroid) {
            directory = await getExternalStorageDirectory();
          } else {
            directory = await getApplicationDocumentsDirectory();
          }

          // Create file path
          final fileName = 'Canteen_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final filePath = '${directory!.path}/$fileName';

          // Save file
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          print('PDF file saved at: $filePath');

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
      print('PDF Export Error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}