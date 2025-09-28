import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class ApplicationAnalyticsScreen extends StatelessWidget {
  final int totalApplications;
  final int totalShortlisted;
  final int totalInterviews;
  final int totalOffers;
  final double averageResponseTime; // in hours

  const ApplicationAnalyticsScreen({
    super.key,
    required this.totalApplications,
    required this.totalShortlisted,
    required this.totalInterviews,
    required this.totalOffers,
    required this.averageResponseTime,
  });

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Analytics'),
        backgroundColor: kPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard('Total Applications', totalApplications.toString(), Colors.blue),
                _buildStatCard('Shortlisted', totalShortlisted.toString(), Colors.orange),
                _buildStatCard('Interviews Scheduled', totalInterviews.toString(), Colors.blueAccent),
                _buildStatCard('Offers Made', totalOffers.toString(), Colors.green),
                _buildStatCard('Avg Response Time (hrs)', averageResponseTime.toStringAsFixed(1), Colors.purple),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Trends & Charts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Placeholder for charts - can integrate charts_flutter or fl_chart
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: const Center(child: Text('Application trends chart placeholder')),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: const Center(child: Text('Job-specific application chart placeholder')),
            ),
          ],
        ),
      ),
    );
  }
}
