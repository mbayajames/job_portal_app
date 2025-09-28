import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../models/application_model.dart';
import '../../../services/employer_application_service.dart';

class ApplicationDetailsScreen extends StatelessWidget {
  final ApplicationModel application;

  const ApplicationDetailsScreen({super.key, required this.application});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Applied':
      case 'Pending Review':
        return Colors.yellow;
      case 'Reviewed':
        return Colors.blue;
      case 'Interview Scheduled':
        return Colors.blueAccent;
      case 'Offer':
      case 'Hired':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _downloadFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint('Could not open $url');
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      final success = await EmployerApplicationService.updateApplicationStatus(application.id, newStatus);
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Return to previous screen
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: kPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant Info
            Text(application.applicantName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Applied for: ${application.jobTitle}'),
            Text('Company: ${application.companyName}'),
            Text('Location: ${application.location}'),
            Text('Job Type: ${application.jobType}'),
            const Divider(height: 32),

            // Application Info
            const Text('Application Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date Submitted: ${DateFormat('MMM dd, yyyy').format(application.appliedDate)}'),
            Text('Current Status: ${application.status}', style: TextStyle(color: _getStatusColor(application.status))),
            const SizedBox(height: 16),

            // Status History
            if (application.statusHistory.isNotEmpty) ...[
              const Text('Status History', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: application.statusHistory.map((statusEntry) {
                  final status = statusEntry['status'] ?? 'Unknown';
                  final date = statusEntry['date'] ?? 'Unknown';
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor: _getStatusColor(status),
                    ),
                    title: Text(status),
                    subtitle: Text(date),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Resume & Cover Letter
            const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (application.resumeUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Resume / CV'),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(application.resumeUrl),
                ),
              ),
            if (application.coverLetter.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Cover Letter'),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(application.coverLetter),
                ),
              ),
            const Divider(height: 32),

            // Actions
            const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, 'Shortlisted'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Shortlist'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, 'Rejected'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateStatus(context, 'Interview Scheduled'),
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                child: const Text('Schedule Interview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}