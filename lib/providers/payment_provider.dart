import '../../services/mpesa_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './auth_provider.dart';
import 'dart:async';

class PaymentResult {
  final bool success;
  final String message;

  PaymentResult({required this.success, required this.message});
}

class PaymentProvider with ChangeNotifier {
  bool _isProcessing = false;
  String? _errorMessage;
  String? _checkoutRequestId;
  String? _lastPhoneNumber;
  int? _lastAmount;
  bool _paymentCompleted = false;
  String? _lastAccountReference;
  String? _lastTransactionDesc;
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  String _paymentStatus = 'IDLE';
  PaymentResult? _paymentResult;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get paymentCompleted => _paymentCompleted;
  String get paymentStatus => _paymentStatus;
  String? get checkoutRequestId => _checkoutRequestId;
  PaymentResult? get payment => _paymentResult;

  // Reset payment state
  void resetPaymentState() {
    _isProcessing = false;
    _errorMessage = null;
    _paymentCompleted = false;
    _paymentStatus = 'IDLE';
    _pollingAttempts = 0;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _paymentResult = null;
    notifyListeners();
  }

  // Pay method for common payment screen
  Future<void> pay({
    required BuildContext context,
    required String phoneNumber,
    required double amount,
    required String userId,
  }) async {
    _paymentResult = null;
    notifyListeners();

    final success = await initiatePayment(
      context: context,
      phoneNumber: phoneNumber,
      amount: amount.toInt(),
      accountReference: 'PremiumUpgrade_$userId',
      transactionDesc: 'Upgrade to Premium Account',
    );

    if (success) {
      _paymentResult = PaymentResult(success: true, message: 'Payment initiated successfully');
    } else {
      _paymentResult = PaymentResult(success: false, message: errorMessage ?? 'Payment failed');
    }
    notifyListeners();
  }

  // Initiate M-Pesa STK Push (NO RETRY LOGIC)
  Future<bool> initiatePayment({
    required BuildContext context,
    required String phoneNumber,
    required int amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    // Prevent multiple simultaneous payments
    if (_isProcessing) {
      _errorMessage = 'Payment already in progress. Please wait.';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    _paymentCompleted = false;
    _paymentStatus = 'INITIATING';
    _lastPhoneNumber = phoneNumber;
    _lastAmount = amount;
    _lastAccountReference = accountReference;
    _lastTransactionDesc = transactionDesc;
    _pollingAttempts = 0;
    notifyListeners();

    try {
      final currentContext = context;
      // Check server connectivity first
      _paymentStatus = 'CONNECTING';
      notifyListeners();

      final isServerReachable = await MpesaService.testConnection();
      if (!isServerReachable) {
        _errorMessage = 'Payment server is unreachable. Please check your internet connection and try again.';
        _paymentStatus = 'FAILED';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      _paymentStatus = 'PROCESSING';
      notifyListeners();

      // Single STK push attempt - NO RETRIES
      final result = await MpesaService.initiateSTKPush(
        phoneNumber: phoneNumber,
        amount: amount,
        accountReference: accountReference,
        transactionDesc: transactionDesc,
      );

      if (result != null && result['success'] == true) {
        _checkoutRequestId = result['data']?['CheckoutRequestID'];

        if (_checkoutRequestId != null && _checkoutRequestId!.isNotEmpty) {
          _paymentStatus = 'STK_SENT';
          notifyListeners();

          // Show STK sent message immediately
          if (currentContext.mounted) {
            _showStkSentDialog(currentContext);
            // Start optimized polling
            _startOptimizedPolling(currentContext, _checkoutRequestId!);
          }
          return true;
        } else {
          _errorMessage = 'Invalid response from payment service. Please try again.';
          _paymentStatus = 'FAILED';
          _isProcessing = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = result?['message'] ?? 'Failed to initiate payment. Please try again.';
        _paymentStatus = 'FAILED';
        _isProcessing = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Payment initiation failed: ${e.toString()}';
      _paymentStatus = 'FAILED';
      debugPrint('Payment initiation error: $e');
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Optimized polling with faster initial checks
  void _startOptimizedPolling(BuildContext context, String checkoutRequestId) {
    _pollingAttempts = 0;
    const maxAttempts = 30; // 2.5 minutes total

    _pollingTimer?.cancel();

    // Start with faster polling, then slow down
    void poll() {
      if (_pollingAttempts >= maxAttempts || !context.mounted || _paymentCompleted) {
        _pollingTimer?.cancel();
        if (!_paymentCompleted && _isProcessing) {
          _handlePaymentTimeout(context);
        }
        return;
      }

      _checkPaymentStatus(context, checkoutRequestId).then((_) {
        if (!_paymentCompleted && _isProcessing && context.mounted) {
          _pollingAttempts++;

          // Dynamic polling intervals: faster initially, slower later
          int interval;
          if (_pollingAttempts < 6) {
            interval = 3; // 3 seconds for first 18 seconds
          } else if (_pollingAttempts < 12) {
            interval = 5; // 5 seconds for next 30 seconds
          } else {
            interval = 7; // 7 seconds for remaining time
          }

          _pollingTimer = Timer(Duration(seconds: interval), poll);
        }
      });
    }

    // Start first poll after short delay
    _pollingTimer = Timer(const Duration(seconds: 2), poll);
  }

  // Check payment status
  Future<void> _checkPaymentStatus(BuildContext context, String checkoutRequestId) async {
    try {
      final statusResponse = await MpesaService.getTransactionStatus(
        checkoutRequestId: checkoutRequestId,
      );

      debugPrint('Payment Status Check (Attempt $_pollingAttempts): $statusResponse');

      if (statusResponse != null && statusResponse['success'] == true) {
        final data = statusResponse['data'];
        final status = data['status']?.toString().toUpperCase() ?? 'PENDING';
        final resultCode = data['resultCode'] ?? -1;
        final resultDesc = (data['resultDesc'] ?? '').toUpperCase();

        _paymentStatus = status;
        notifyListeners();

        // Check for success
        if (resultCode == 0 ||
            status.contains('SUCCESS') ||
            status.contains('COMPLETE') ||
            status == 'CONFIRMED' ||
            status == 'SUCCESSFUL') {

          _pollingTimer?.cancel();
          if (context.mounted) {
            await _handlePaymentSuccess(context, data);
          }
          return;
        }

        // Check for cancellation
        if (resultCode == 1 ||
            status == 'CANCELLED' ||
            resultDesc.contains('CANCEL') ||
            resultDesc.contains('USER_CANCELLED')) {

          _pollingTimer?.cancel();
          if (context.mounted) {
            _handlePaymentCancellation(context);
          }
          return;
        }

        // Check for other failures
        if (resultCode > 1) {
          _pollingTimer?.cancel();
          if (context.mounted) {
            _handlePaymentFailure(context, data['resultDesc'] ?? 'Payment failed');
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      // Don't stop polling for network errors, just log them
    }
  }

  // Handle payment success
  Future<void> _handlePaymentSuccess(BuildContext context, Map<String, dynamic> paymentData) async {
    try {
      _paymentStatus = 'UPGRADING';
      notifyListeners();

      await _upgradeToPremium(context, paymentData);

      _paymentCompleted = true;
      _paymentStatus = 'COMPLETED';
      _isProcessing = false;
      notifyListeners();

      if (context.mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      debugPrint('Error handling payment success: $e');
      _errorMessage = 'Payment successful but failed to update account: $e';
      _paymentStatus = 'SUCCESS_ERROR';
      _isProcessing = false;
      notifyListeners();

      if (context.mounted) {
        _showPartialSuccessDialog(context);
      }
    }
  }

  // Handle payment cancellation
  void _handlePaymentCancellation(BuildContext context) {
    _errorMessage = 'Payment was cancelled by user';
    _paymentStatus = 'CANCELLED';
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      _showErrorDialog(context, _errorMessage!);
    }
  }

  // Handle payment failure
  void _handlePaymentFailure(BuildContext context, String reason) {
    _errorMessage = 'Payment failed: $reason';
    _paymentStatus = 'FAILED';
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      _showErrorDialog(context, _errorMessage!);
    }
  }

  // Handle payment timeout
  void _handlePaymentTimeout(BuildContext context) {
    _errorMessage = 'Payment status check timed out. Please check your M-Pesa messages or contact support.';
    _paymentStatus = 'TIMEOUT';
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      _showTimeoutDialog(context);
    }
  }

  // Upgrade or renew user to premium
  Future<void> _upgradeToPremium(BuildContext context, Map<String, dynamic> paymentData) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      throw Exception('User not found');
    }

    final userId = authProvider.user!.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Prepare update data
    final updateData = {
      'role': 'premium',
      'premiumUpdatedAt': FieldValue.serverTimestamp(),
      'premiumExpiry': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'lastPayment': {
        'checkoutRequestId': paymentData['checkoutRequestId'] ?? _checkoutRequestId,
        'merchantRequestId': paymentData['merchantRequestId'],
        'amount': paymentData['amount'] ?? _lastAmount,
        'phoneNumber': paymentData['phoneNumber'] ?? _lastPhoneNumber,
        'mpesaReceiptNumber': paymentData['mpesaReceiptNumber'] ?? '',
        'transactionDate': paymentData['transactionDate'] ?? DateTime.now().toIso8601String(),
        'status': paymentData['status'] ?? 'SUCCESS',
        'resultCode': paymentData['resultCode'] ?? 0,
      },
    };

    await docRef.update(updateData);

    // Refresh user data
    await authProvider.loadCurrentUser();
  }

  // Show STK sent dialog
  void _showStkSentDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('STK Push Sent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Check your phone for the M-Pesa STK push notification and enter your PIN to complete the payment.'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Color(0xFF4CAF50)),
            const SizedBox(height: 8),
            Text('Status: $_paymentStatus',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelPayment();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Cancel payment
  void _cancelPayment() {
    _pollingTimer?.cancel();
    _isProcessing = false;
    _paymentStatus = 'CANCELLED';
    _errorMessage = 'Payment cancelled by user';
    notifyListeners();
  }

  // Show success dialog
  void _showSuccessDialog(BuildContext context) {
    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.settings.name != null);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isRenewal = authProvider.userRole == 'premium';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    isRenewal ? Icons.refresh : Icons.star,
                    color: const Color(0xFF4CAF50),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRenewal
                        ? 'Premium Renewed!'
                        : 'Welcome to Premium!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRenewal
                        ? 'Your premium subscription has been extended for another 30 days.'
                        : 'You now have unlimited access to all premium features.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Show partial success dialog
  void _showPartialSuccessDialog(BuildContext context) {
    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.settings.name != null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Payment Received'),
          ],
        ),
        content: const Text(
          'Your payment was successful, but there was an issue updating your account. Please contact support with your transaction details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Contact Support'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Show timeout dialog
  void _showTimeoutDialog(BuildContext context) {
    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.settings.name != null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Payment Timeout'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We couldn\'t confirm your payment status. Please check your M-Pesa messages to see if the payment went through.',
            ),
            SizedBox(height: 12),
            Text(
              'If you were charged, your account will be updated automatically. If not, please try again.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Check Messages'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Show error dialog with retry option
  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.settings.name != null);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure you have sufficient balance and try again.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Only retry if we have the necessary data
              if (_lastPhoneNumber != null && _lastAmount != null) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                initiatePayment(
                  context: context,
                  phoneNumber: _lastPhoneNumber!,
                  amount: _lastAmount!,
                  accountReference: _lastAccountReference ?? 
                      (authProvider.userRole == 'premium' ? 'Premium Renewal' : 'Premium Upgrade'),
                  transactionDesc: _lastTransactionDesc ??
                      (authProvider.userRole == 'premium'
                          ? 'Renew Premium Account'
                          : 'Upgrade to Premium Account'),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}