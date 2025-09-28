import 'package:flutter/material.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example static data for previous payments
    final payments = [
      {"amount": 49.99, "date": "2025-09-01", "status": "Completed"},
      {"amount": 19.99, "date": "2025-08-15", "status": "Completed"},
      {"amount": 29.99, "date": "2025-07-20", "status": "Failed"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.payment, color: Colors.blue),
              title: Text('\$${payment["amount"]}'),
              subtitle: Text('Date: ${payment["date"]}'),
              trailing: Text(
                payment["status"] as String,
                style: TextStyle(
                  color: (payment["status"] as String) == "Completed"
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
