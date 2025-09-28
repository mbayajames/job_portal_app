import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/job_provider.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  const JobApplicantsScreen({required this.jobId, super.key});

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  late Future<List<Map<String, dynamic>>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    _applicationsFuture =
        Provider.of<JobProvider>(context, listen: false).fetchApplications(widget.jobId);
  }

  void _updateStatus(String applicationId, String status) async {
    final provider = Provider.of<JobProvider>(context, listen: false);
    try {
      await provider.updateApplicationStatus(applicationId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $status successfully')),
        );
        // Refresh the applications list
        setState(() {
          _loadApplications();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applicants")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final applications = snapshot.data ?? [];
          if (applications.isEmpty) {
            return const Center(child: Text("No applicants yet"));
          }

          return ListView.separated(
            itemCount: applications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final app = applications[index];
              return ListTile(
                title: Text("Applicant ID: ${app['applicantId']}"),
                subtitle: Text("Status: ${app['status']}"),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateStatus(app['id'], 'accepted'),
                      child: const Text("Accept"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => _updateStatus(app['id'], 'rejected'),
                      child: const Text("Reject"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _updateStatus(app['id'], 'hired'),
                      child: const Text("Hire"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
