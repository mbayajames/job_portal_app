// providers/screens/employer/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:job_portal_app/providers/%20%60.dart';
import 'package:job_portal_app/models/payment_model.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.jobData,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _phoneValidated = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserPhoneNumber();
    Provider.of<PaymentProvider>(context, listen: false).resetPaymentState();
  }

  Future<void> _loadUserPhoneNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final String? phoneNumber = userDoc.data()?['phoneNumber'];
      if (phoneNumber != null && _isValidKenyanPhoneNumber(phoneNumber)) {
        setState(() {
          _phoneController.text = _formatPhoneNumberForDisplay(phoneNumber);
          _phoneValidated = true;
        });
      }
    }
  }

  bool _isValidKenyanPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    return RegExp(r'^(?:\+254|0)7\d{8}$').hasMatch(cleaned);
  }

  String _formatPhoneNumberForDisplay(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('0')) {
      return '+254${cleaned.substring(1)}';
    }
    return cleaned;
  }

  String _formatPhoneNumberForMpesa(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('0')) {
      return '+254${cleaned.substring(1)}';
    }
    return cleaned;
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser!;

    const int amount = 100;
    final String accountReference = 'JobPost_${DateTime.now().millisecondsSinceEpoch}';
    final String transactionDesc = 'Payment for job posting: ${widget.jobData['title']}';
    final String formattedPhone = _formatPhoneNumberForMpesa(_phoneController.text);

    final success = await paymentProvider.initiatePayment(
      context: context,
      phoneNumber: formattedPhone,
      amount: amount,
      accountReference: accountReference,
      transactionDesc: transactionDesc,
    );

    if (success && paymentProvider.paymentCompleted) {
      await _storePayment(
        user.uid,
        paymentProvider,
        amount,
        formattedPhone,
        accountReference,
        transactionDesc,
      );
      if (!mounted) return;
      widget.onPaymentSuccess();
      Navigator.pop(context);
    }
  }

  Future<void> _storePayment(
    String userId,
    PaymentProvider paymentProvider,
    int amount,
    String phoneNumber,
    String accountReference,
    String transactionDesc,
  ) async {
    try {
      final payment = PaymentModel(
        id: paymentProvider.checkoutRequestId ?? accountReference,
        phoneNumber: phoneNumber,
        amount: amount.toString(),
        status: paymentProvider.paymentStatus,
        transactionDesc: transactionDesc,
        createdAt: DateTime.now(),
        checkoutRequestId: paymentProvider.checkoutRequestId,
        subscriptionStatus: null,
        subscriptionStartDate: null,
        subscriptionExpiryDate: null,
        mpesaReceiptNumber: paymentProvider.mpesaReceiptNumber,
        merchantRequestId: paymentProvider.merchantRequestId,
        resultCode: paymentProvider.resultCode ?? 0,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .doc(payment.id)
          .set(payment.toMap());
    } catch (e) {
      debugPrint('Error storing payment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful but failed to store transaction: $e'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment for Job Posting'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Job Title: ${widget.jobData['title']}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: 100 KES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+254 7XX XXX XXX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      prefixIcon: Icon(Icons.phone, color: Theme.of(context).primaryColor),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      if (!_isValidKenyanPhoneNumber(value)) {
                        return 'Please enter a valid Kenyan phone number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _phoneValidated = _isValidKenyanPhoneNumber(value);
                      });
                    },
                  ),
                  if (paymentProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        paymentProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: paymentProvider.isProcessing || !_phoneValidated
                          ? null
                          : _initiatePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: paymentProvider.isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Pay with M-Pesa',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (paymentProvider.paymentStatus != 'IDLE')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Payment Status: ${paymentProvider.paymentStatus}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}