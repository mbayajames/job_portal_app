import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/application_model.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/job_provider.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final ApplicationModel application;

  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  late ApplicationProvider applicationProvider;
  late ApplicationModel currentApplication;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    applicationProvider = Provider.of<ApplicationProvider>(context, listen: false);
    currentApplication = widget.application;
  }

  void _toggleFavorite() {
    applicationProvider.toggleFavorite(currentApplication.id);
    setState(() {
      currentApplication = currentApplication.copyWith(isFavorite: !currentApplication.isFavorite);
    });
  }

  Future<void> _messageEmployer() async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = await jobProvider.getJobById(currentApplication.jobId);

    if (job == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job details not found')),
        );
      }
      return;
    }

    try {
      final employerDoc = await FirebaseFirestore.instance
          .collection('employers')
          .doc(job.employerId)
          .get();

      if (!employerDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employer information not found')),
          );
        }
        return;
      }

      final employerData = employerDoc.data();
      final email = employerData?['email'] as String?;

      if (email == null || email.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employer email not available')),
          );
        }
        return;
      }

      final emailUri = Uri.parse(
        'mailto:$email?subject=Regarding my application for ${currentApplication.jobTitle}',
      );

      try {
        await launchUrl(emailUri);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email client')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: const Color(0xFF1a73e8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Job Info
            Text(
              currentApplication.jobTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              currentApplication.companyName,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(currentApplication.jobType)),
                const SizedBox(width: 8),
                Chip(label: Text(currentApplication.status)),
              ],
            ),
            const Divider(height: 30, thickness: 1),

            // 🔹 Applicant Info
            const Text("Applicant Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Name: ${currentApplication.applicantName}"),
            Text("Email: ${currentApplication.email}"),
            Text("Phone: ${currentApplication.phone}"),
            const Divider(height: 30, thickness: 1),

            // 🔹 Documents
            const Text("Documents",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (currentApplication.resumeUrl.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.file_present),
                label: const Text("View Resume"),
                onPressed: () async {
                  final url = Uri.parse(currentApplication.resumeUrl);
                  try {
                    await launchUrl(url);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open resume')),
                      );
                    }
                  }
                },
              ),
            if (currentApplication.coverLetter.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.description),
                label: const Text("View Cover Letter"),
                onPressed: () async {
                  final url = Uri.parse(currentApplication.coverLetter);
                  try {
                    await launchUrl(url);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open cover letter')),
                      );
                    }
                  }
                },
              ),
            const Divider(height: 30, thickness: 1),

            // 🔹 Applied Date
            Text(
              "Applied on: ${currentApplication.appliedDate.toLocal().toIso8601String().split('T')[0]}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 🔹 Status History
            if (currentApplication.statusHistory.isNotEmpty) ...[
              const Text("Status History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentApplication.statusHistory.length,
                itemBuilder: (context, index) {
                  final history = currentApplication.statusHistory[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history),
                    title: Text(history['status'] ?? ''),
                    subtitle: Text(history['date'] ?? ''),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),
            // 🔹 Optional Actions
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(currentApplication.isFavorite ? Icons.favorite : Icons.favorite_border),
                  label: Text(currentApplication.isFavorite ? "Unmark as Favorite" : "Mark as Favorite"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _messageEmployer,
                  icon: const Icon(Icons.send),
                  label: const Text("Message Employer"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}