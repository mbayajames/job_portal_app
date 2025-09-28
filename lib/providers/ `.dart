// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:job_portal_app/services/mpesa_service.dart';
import 'dart:async';

class PaymentProvider with ChangeNotifier {
  bool _isProcessing = false;
  String? _errorMessage;
  String? _checkoutRequestId;
  String? _merchantRequestId;
  String? _mpesaReceiptNumber;
  int? _resultCode;
  String? _lastPhoneNumber;
  int? _lastAmount;
  bool _paymentCompleted = false;
  String? _lastAccountReference;
  String? _lastTransactionDesc;
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  String _paymentStatus = 'IDLE';

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get paymentCompleted => _paymentCompleted;
  String get paymentStatus => _paymentStatus;
  String? get checkoutRequestId => _checkoutRequestId;
  String? get merchantRequestId => _merchantRequestId;
  String? get mpesaReceiptNumber => _mpesaReceiptNumber;
  int? get resultCode => _resultCode;

  void resetPaymentState() {
    _isProcessing = false;
    _errorMessage = null;
    _paymentCompleted = false;
    _paymentStatus = 'IDLE';
    _pollingAttempts = 0;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _checkoutRequestId = null;
    _merchantRequestId = null;
    _mpesaReceiptNumber = null;
    _resultCode = null;
    notifyListeners();
  }

  Future<bool> initiatePayment({
    required BuildContext context,
    required String phoneNumber,
    required int amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
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
      _paymentStatus = 'CONNECTING';
      notifyListeners();

      final isServerReachable = await MpesaService.testConnection();
      if (!isServerReachable) {
        _errorMessage =
            'Payment server is unreachable. Please check your internet connection and try again.';
        _paymentStatus = 'FAILED';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      _paymentStatus = 'PROCESSING';
      notifyListeners();

      final result = await MpesaService.initiateSTKPush(
        phoneNumber: phoneNumber,
        amount: amount,
        accountReference: accountReference,
        transactionDesc: transactionDesc,
      );

      if (result != null && result['success'] == true) {
        _checkoutRequestId = result['data']?['CheckoutRequestID'];
        _merchantRequestId = result['data']?['MerchantRequestID'];

        if (_checkoutRequestId != null && _checkoutRequestId!.isNotEmpty) {
          _paymentStatus = 'STK_SENT';
          notifyListeners();

          if (context.mounted) {
            _showStkSentDialog(context);
            _startOptimizedPolling(context, _checkoutRequestId!);
          }
          return true;
        } else {
          _errorMessage =
              'Invalid response from payment service. Please try again.';
          _paymentStatus = 'FAILED';
          _isProcessing = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage =
            result?['message'] ?? 'Failed to initiate payment. Please try again.';
        _paymentStatus = 'FAILED';
        _isProcessing = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Payment initiation failed: $e';
      _paymentStatus = 'FAILED';
      debugPrint('Payment initiation error: $e');
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void _startOptimizedPolling(BuildContext context, String checkoutRequestId) {
    _pollingAttempts = 0;
    const maxAttempts = 30;

    _pollingTimer?.cancel();

    void poll() {
      if (_pollingAttempts >= maxAttempts ||
          !context.mounted ||
          _paymentCompleted) {
        _pollingTimer?.cancel();
        if (!_paymentCompleted && _isProcessing) {
          _handlePaymentTimeout(context);
        }
        return;
      }

      _checkPaymentStatus(context, checkoutRequestId).then((_) {
        if (!_paymentCompleted && _isProcessing && context.mounted) {
          _pollingAttempts++;
          int interval =
              _pollingAttempts < 6 ? 3 : (_pollingAttempts < 12 ? 5 : 7);
          _pollingTimer = Timer(Duration(seconds: interval), poll);
        }
      });
    }

    _pollingTimer = Timer(const Duration(seconds: 2), poll);
  }

  Future<void> _checkPaymentStatus(
      BuildContext context, String checkoutRequestId) async {
    try {
      final statusResponse = await MpesaService.getTransactionStatus(
        checkoutRequestId: checkoutRequestId,
      );

      debugPrint(
          'Payment Status Check (Attempt $_pollingAttempts): $statusResponse');

      if (statusResponse != null && statusResponse['success'] == true) {
        final data = statusResponse['data'];
        final status = data['status']?.toString().toUpperCase() ?? 'PENDING';
        final resultCode = data['resultCode'] ?? -1;
        final resultDesc = (data['resultDesc'] ?? '').toUpperCase();

        _paymentStatus = status;
        _mpesaReceiptNumber = data['mpesaReceiptNumber'];
        _merchantRequestId = data['merchantRequestId'];
        _resultCode = resultCode;
        notifyListeners();

        if ((resultCode == 0 ||
                status == 'SUCCESS' ||
                status == 'COMPLETE' ||
                status == 'CONFIRMED') &&
            context.mounted) {
          _pollingTimer?.cancel();
          await _handlePaymentSuccess(context, data);
          return;
        }

        if ((resultCode == 1 ||
                status == 'CANCELLED' ||
                resultDesc.contains('CANCEL')) &&
            context.mounted) {
          _pollingTimer?.cancel();
          _handlePaymentCancellation(context);
          return;
        }

        if (resultCode > 1 && context.mounted) {
          _pollingTimer?.cancel();
          _handlePaymentFailure(context, data['resultDesc'] ?? 'Payment failed');
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
  }

  Future<void> _handlePaymentSuccess(
      BuildContext context, Map<String, dynamic> paymentData) async {
    try {
      _paymentStatus = 'COMPLETED';
      _paymentCompleted = true;
      _isProcessing = false;
      notifyListeners();

      if (context.mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      debugPrint('Error handling payment success: $e');
      _errorMessage = 'Payment successful but failed to process: $e';
      _paymentStatus = 'SUCCESS_ERROR';
      _isProcessing = false;
      notifyListeners();

      if (context.mounted) {
        _showPartialSuccessDialog(context);
      }
    }
  }

  void _handlePaymentCancellation(BuildContext context) {
    _errorMessage = 'Payment was cancelled by user';
    _paymentStatus = 'CANCELLED';
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      _showErrorDialog(context, _errorMessage!);
    }
  }

  void _handlePaymentFailure(BuildContext context, String reason) {
    _errorMessage = 'Payment failed: $reason';
    _paymentStatus = 'FAILED';
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      _showErrorDialog(context, _errorMessage!);
    }
  }

  void _handlePaymentTimeout(BuildContext context) {
    _errorMessage =
        'Payment status check timed out. Please check your M-Pesa messages or contact support.';
    _paymentStatus = 'TIMEOUT';
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      _showTimeoutDialog(context);
    }
  }

  void _showStkSentDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.phone_android, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('STK Push Sent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Check your phone for the M-Pesa STK push notification and enter your PIN to complete the payment.',
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              'Status: $_paymentStatus',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelPayment();
            },
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _cancelPayment() {
    _pollingTimer?.cancel();
    _isProcessing = false;
    _paymentStatus = 'CANCELLED';
    _errorMessage = 'Payment cancelled by user';
    notifyListeners();
  }

  void _showSuccessDialog(BuildContext context) {
    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(width: 8),
            const Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check,
                    color: Theme.of(context).primaryColor,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Completed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your payment for the job posting "${_lastTransactionDesc ?? 'Job Posting'}" was successful.',
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPartialSuccessDialog(BuildContext context) {
    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Payment Received'),
          ],
        ),
        content: const Text(
          'Your payment was successful, but there was an issue processing it. Please contact support with your transaction details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Contact Support'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog(BuildContext context) {
    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'If you were charged, your job posting will be processed automatically. If not, please try again.',
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
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              if (_lastPhoneNumber != null && _lastAmount != null) {
                initiatePayment(
                  context: context,
                  phoneNumber: _lastPhoneNumber!,
                  amount: _lastAmount!,
                  accountReference: _lastAccountReference ??
                      'JobPost_${DateTime.now().millisecondsSinceEpoch}',
                  transactionDesc:
                      _lastTransactionDesc ?? 'Job Posting Payment',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

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
