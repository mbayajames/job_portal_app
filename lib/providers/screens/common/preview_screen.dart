import 'package:flutter/material.dart';

class PreviewScreen extends StatelessWidget {
  final String jobTitle;
  final String coverLetter;
  const PreviewScreen({super.key, required this.jobTitle, required this.coverLetter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Preview')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job: $jobTitle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Cover Letter:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(coverLetter),
          ],
        ),
      ),
    );
  }
}
