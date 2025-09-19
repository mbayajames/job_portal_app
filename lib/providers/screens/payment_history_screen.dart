import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';

class PaymentHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final paymentService = PaymentService();
    final user = authProvider.user;
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please sign in to view payment history', style: TextStyle(color: Colors.black))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: paymentService.getPaymentHistory(user.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final payments = snapshot.data!;
            if (payments.isEmpty) {
              return Center(child: Text('No payment history', style: TextStyle(color: Colors.black)));
            }
            return ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      payment['description'] ?? 'Payment',
                      style: TextStyle(color: Colors.black),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount: ${payment['amount'] ?? 'N/A'}', style: TextStyle(color: Colors.black54)),
                        Text(
                          payment['timestamp'] != null
                              ? (payment['timestamp'] as Timestamp).toDate().toString()
                              : 'Unknown date',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}