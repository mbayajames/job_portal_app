import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:job_portal_app/providers/job_provider.dart';

class JobListingScreen extends StatelessWidget {
  final String? query;

  const JobListingScreen({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final jobs = query != null && query!.isNotEmpty
        ? jobProvider.jobsForApplicants.where((job) =>
            job.title.toLowerCase().contains(query!.toLowerCase()) ||
            job.company.toLowerCase().contains(query!.toLowerCase()) ||
            job.description.toLowerCase().contains(query!.toLowerCase())).toList()
        : jobProvider.jobsForApplicants;

    return Scaffold(
      appBar: AppBar(
        title: Text(query != null && query!.isNotEmpty
            ? 'Job Listings for "$query"'
            : 'All Jobs'),
        backgroundColor: Colors.blue,
      ),
      body: jobs.isEmpty
          ? Center(
              child: Text(
                query != null && query!.isNotEmpty
                    ? 'No jobs found for "$query"'
                    : 'No jobs available',
                style: const TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${job.company} • ${job.location}'),
                    trailing: Text(job.employmentType),
                    onTap: () {
                      // Navigate to Job Details Screen
                      // Navigator.pushNamed(context, RouteNames.jobDetails, arguments: job.id);
                    },
                  ),
                );
              },
            ),
    );
  }
}
