import 'package:flutter/material.dart';
import '../../models/job_model.dart';

class JobDetailsScreen extends StatelessWidget {
  final JobModel job;
  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(job.location, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            Text(job.description, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
