import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Future<Map<String, dynamic>> _fetchAnalytics() async {
    final jobsSnapshot = await FirebaseFirestore.instance.collection('jobs').get();
    final applicationsSnapshot = await FirebaseFirestore.instance.collection('applications').get();

    final totalJobs = jobsSnapshot.docs.length;
    final totalApplications = applicationsSnapshot.docs.length;

    // Group applications by job
    Map<String, int> appsPerJob = {};
    for (var app in applicationsSnapshot.docs) {
      final jobId = app['jobId'];
      appsPerJob[jobId] = (appsPerJob[jobId] ?? 0) + 1;
    }

    return {
      "totalJobs": totalJobs,
      "totalApplications": totalApplications,
      "appsPerJob": appsPerJob,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        backgroundColor: const Color(0xFF1a73e8),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No analytics available"));
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard("Total Jobs", data["totalJobs"].toString(), Colors.blue),
                const SizedBox(height: 12),
                _buildStatCard("Total Applications", data["totalApplications"].toString(), Colors.green),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: data["appsPerJob"].entries.map<Widget>((entry) {
                      return ListTile(
                        leading: const Icon(Icons.work, color: Colors.orange),
                        title: Text("Job ID: ${entry.key}"),
                        subtitle: Text("Applications: ${entry.value}"),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
