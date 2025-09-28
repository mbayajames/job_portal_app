import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MpesaService {
  static const String _baseUrl = 'https://mpesa-server-icfv.onrender.com';
  static const Duration _timeout = Duration(seconds: 30);
  static final Set<String> _activeRequests = <String>{}; // Track active requests
  static final Map<String, DateTime> _requestTimestamps = <String, DateTime>{}; // Track request times

  // Test server connection
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$_baseUrl/');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('Connection Test Response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection Test Error: $e');
      return false;
    }
  }

  // STK Push - Initiate M-Pesa payment (NO RETRY to prevent duplicates)
  static Future<Map<String, dynamic>?> initiateSTKPush({
    required String phoneNumber,
    required int amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    // Create a unique identifier for this request
    final requestId = '${phoneNumber}_${amount}_${accountReference}';
    
    // Check if this exact request is already being processed
    if (_activeRequests.contains(requestId)) {
      debugPrint('Duplicate request blocked: $requestId');
      return {
        'success': false,
        'message': 'Request already in progress. Please wait.',
      };
    }

    // Check if similar request was made recently (within 2 minutes)
    final now = DateTime.now();
    if (_requestTimestamps.containsKey(requestId)) {
      final lastRequest = _requestTimestamps[requestId]!;
      if (now.difference(lastRequest).inMinutes < 2) {
        debugPrint('Request too recent: $requestId');
        return {
          'success': false,
          'message': 'Please wait before making another payment request.',
        };
      }
    }

    // Mark request as active
    _activeRequests.add(requestId);
    _requestTimestamps[requestId] = now;

    try {
      final url = Uri.parse('$_baseUrl/mpesa/stkpush');
      final body = jsonEncode({
        'phoneNumber': phoneNumber,
        'amount': amount,
        'accountReference': accountReference,
        'transactionDesc': transactionDesc,
      });

      debugPrint('STK Push Request: $body');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(_timeout);

      debugPrint('STK Push Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Handle different response structures
          String? checkoutRequestId = data['data']?['CheckoutRequestID'] ?? 
                                     data['CheckoutRequestID'] ?? 
                                     data['data']?['checkoutRequestId'] ?? 
                                     data['checkoutRequestId'];
          
          String? merchantRequestId = data['data']?['MerchantRequestID'] ?? 
                                     data['MerchantRequestID'] ?? 
                                     data['data']?['merchantRequestId'] ?? 
                                     data['merchantRequestId'];
          
          if (checkoutRequestId == null) {
            throw Exception('CheckoutRequestID not found in response');
          }

          return {
            'success': true,
            'data': {
              'CheckoutRequestID': checkoutRequestId,
              'MerchantRequestID': merchantRequestId ?? '',
              'ResponseCode': data['ResponseCode'] ?? '0',
              'ResponseDescription': data['ResponseDescription'] ?? 'Success',
            },
          };
        } else {
          throw Exception(data['message'] ?? 'STK Push failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('STK Push Error: $e');
      return {
        'success': false,
        'message': 'Failed to initiate payment: $e',
      };
    } finally {
      // Remove from active requests after a delay to prevent immediate duplicates
      Future.delayed(const Duration(seconds: 30), () {
        _activeRequests.remove(requestId);
      });
    }
  }

  // Query STK Push status
  static Future<Map<String, dynamic>?> querySTKPushStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/stkquery');
      final body = jsonEncode({'checkoutRequestId': checkoutRequestId});

      debugPrint('STK Query Request: $body');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(_timeout);

      debugPrint('STK Query Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Query failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('STK Query Error: $e');
      return {'success': false, 'message': 'Query failed: $e'};
    }
  }

  // Get transaction status from your server (optimized)
  static Future<Map<String, dynamic>?> getTransactionStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/status/$checkoutRequestId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15)); // Reduced timeout for faster polling

      debugPrint('Transaction Status Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final tx = data['data'];
          return {
            'success': true,
            'data': {
              'checkoutRequestId': tx['checkoutRequestId'],
              'merchantRequestId': tx['merchantRequestId'],
              'status': tx['status']?.toString().toUpperCase() ?? 'PENDING',
              'amount': tx['amount'],
              'phoneNumber': tx['phoneNumber'],
              'mpesaReceiptNumber': tx['mpesaReceiptNumber'] ?? '',
              'transactionDate': tx['transactionDate'] ?? DateTime.now().toIso8601String(),
              'resultCode': tx['resultCode'] ?? -1,
              'resultDesc': tx['resultDesc'] ?? '',
            },
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Status check failed',
            'data': {
              'status': 'PENDING',
              'resultCode': -1,
              'resultDesc': data['message'] ?? 'Status unclear',
            },
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'data': {
            'status': 'PENDING',
            'resultCode': -1,
            'resultDesc': 'Transaction not found yet',
          },
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Transaction Status Error: $e');
      return {
        'success': false,
        'message': 'Failed to check transaction status: $e',
        'data': {
          'status': 'PENDING',
          'resultCode': -1,
          'resultDesc': 'Error checking status: $e',
        },
      };
    }
  }

  // Get all transactions
  static Future<List<Map<String, dynamic>>?> getAllTransactions() async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/transactions');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      debugPrint('All Transactions Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch transactions');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get Transactions Error: $e');
      return null;
    }
  }

  // B2C Payment (Send money to customer)
  static Future<Map<String, dynamic>?> initiateB2CPayment({
    required String phoneNumber,
    required double amount,
    required String remarks,
    String? occasion,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/b2c');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'amount': amount,
          'remarks': remarks,
          'occasion': occasion ?? 'Payment',
        }),
      ).timeout(_timeout);

      debugPrint('B2C Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'B2C payment failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('B2C Payment Error: $e');
      rethrow;
    }
  }

  // Check account balance
  static Future<Map<String, dynamic>?> checkAccountBalance() async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/balance');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      debugPrint('Balance Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Balance check failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Balance Check Error: $e');
      rethrow;
    }
  }

  // Validate Kenyan phone number format
  static bool isValidKenyanPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleanPhone.startsWith('254') && cleanPhone.length == 12) {
      return RegExp(r'^254[17]\d{8}$').hasMatch(cleanPhone);
    } else if (cleanPhone.length == 10) {
      return RegExp(r'^0[17]\d{8}$').hasMatch(cleanPhone);
    }
    return false;
  }

  // Format phone number for M-Pesa
  static String formatPhoneNumberForMpesa(String phoneNumber) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
      return '254${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('254')) {
      return cleanPhone;
    } else if (cleanPhone.length == 9) {
      return '254$cleanPhone';
    }
    return cleanPhone;
  }

  // Format phone number for display
  static String formatPhoneNumberForDisplay(String phoneNumber) {
    final formatted = formatPhoneNumberForMpesa(phoneNumber);
    if (formatted.startsWith('254') && formatted.length == 12) {
      return '+254 ${formatted.substring(3, 6)} ${formatted.substring(6, 9)} ${formatted.substring(9)}';
    }
    return phoneNumber;
  }

  // Clear old request data (call this periodically to prevent memory leaks)
  static void clearOldRequests() {
    final now = DateTime.now();
    _requestTimestamps.removeWhere((key, value) => 
        now.difference(value).inHours > 1);
  }
}
