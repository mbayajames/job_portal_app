import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth_provider.dart';
import '../../../services/application_service.dart';
import '../../../core/routes.dart';

class EmployerApplicationsScreen extends StatelessWidget {
  final String jobId;

  const EmployerApplicationsScreen({super.key, required this.jobId});

  Future<void> _updateStatus(BuildContext context, String applicationId, String userId, String status) async {
    final applicationService = ApplicationService();
    try {
      await applicationService.updateApplicationStatus(applicationId, status, userId, jobId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application status updated to $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final applicationService = ApplicationService();
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (authProvider.user == null || authProvider.currentUserData?['role'] != 'employer') {
      return Scaffold(
        body: Center(child: Text('Access restricted to employers', style: TextStyle(color: Colors.black))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Applications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: applicationService.getJobApplications(jobId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final applications = snapshot.data!;
          if (applications.isEmpty) {
            return Center(child: Text('No applications for this job', style: TextStyle(color: Colors.black)));
          }
          return ListView.builder(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                child: ListTile(
                  title: Text('Applicant: ${app['details']['fullName'] ?? 'Unknown'}', style: TextStyle(color: Colors.black)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${app['status'] ?? 'Pending'}', style: TextStyle(color: Colors.black54)),
                      Text('Submitted: ${app['createdAt'] != null ? (app['createdAt'] as Timestamp).toDate().toString() : 'N/A'}',
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _updateStatus(context, app['id'], app['userId'], value),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'Accepted', child: Text('Accept')),
                      PopupMenuItem(value: 'Rejected', child: Text('Reject')),
                      PopupMenuItem(value: 'Pending', child: Text('Pending')),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.preview, arguments: {
                      'jobId': jobId,
                      'userData': {'fullName': app['details']['fullName'], 'email': app['details']['email']},
                      'details': app['details'],
                      'resumeUrl': app['resumeUrl'],
                      'coverLetterUrl': app['coverLetterUrl'],
                      'questionAnswers': app['questionAnswers'],
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}