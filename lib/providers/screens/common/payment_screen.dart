import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ `.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String userId;

  const PaymentScreen({super.key, required this.amount, required this.userId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    final success = await paymentProvider.initiatePayment(
      context: context,
      phoneNumber: phoneNumber,
      amount: widget.amount.toInt(),
      accountReference: 'PremiumUpgrade_${widget.userId}',
      transactionDesc: 'Upgrade to Premium Account',
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initiated successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(paymentProvider.errorMessage ?? 'Payment failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.payment, size: 60, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Amount: \$${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'User ID: ${widget.userId}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (e.g., 2547XXXXXXXX)',
                border: OutlineInputBorder(),
                hintText: 'Enter your M-Pesa registered number',
              ),
            ),
            const SizedBox(height: 30),
            paymentProvider.isProcessing
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Pay Now'),
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
