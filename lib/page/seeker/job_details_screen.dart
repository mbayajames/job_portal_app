import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/saved_job_provider.dart';
import '../../core/route_names.dart';

class JobModelDetailsScreen extends StatelessWidget {
  static const String routeName = RouteNames.jobDetails;

  const JobModelDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final JobModel job = ModalRoute.of(context)!.settings.arguments as JobModel;
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final savedJobProvider = Provider.of<SavedJobProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(
              savedJobProvider.isJobSaved(job.id) ? Icons.bookmark : Icons.bookmark_border,
              color: savedJobProvider.isJobSaved(job.id) ? Colors.white : Colors.white70,
            ),
            onPressed: () {
              if (savedJobProvider.isJobSaved(job.id)) {
                final savedJob = savedJobProvider.savedJobs.firstWhere((sj) => sj.jobId == job.id);
                savedJobProvider.unsaveJob(savedJob.id);
              } else {
                savedJobProvider.saveJob(job.id);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(job),
            SizedBox(height: 24),
            
            // JobModel Details Section
            _buildDetailsSection(job),
            SizedBox(height: 24),
            
            // Requirements Section
            _buildRequirementsSection(job),
            SizedBox(height: 24),
            
            // Responsibilities Section
            _buildResponsibilitiesSection(job),
            SizedBox(height: 24),
            
            // Benefits Section
            _buildBenefitsSection(job),
            SizedBox(height: 24),
            
            // Application Instructions
            _buildApplicationInstructions(job),
          ],
        ),
      ),
      bottomNavigationBar: _buildApplyButton(job, context, applicationProvider),
    );
  }

  Widget _buildHeaderSection(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        SizedBox(height: 8),
        Text(
          job.company,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _buildInfoChip(Icons.location_on, job.isRemote ? 'Remote' : job.location),
            SizedBox(width: 8),
            _buildInfoChip(Icons.work, job.employmentType),
            SizedBox(width: 8),
            _buildInfoChip(Icons.business_center, job.experienceLevel),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(Icons.attach_money, job.salaryRange),
            SizedBox(width: 8),
            _buildInfoChip(Icons.category, job.category),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(
        text,
        style: TextStyle(fontSize: 12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDetailsSection(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Description',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          job.description,
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        SizedBox(height: 16),
        _buildDetailItem('Posted', _formatDate(job.createdAt)),
        _buildDetailItem('Application Deadline', _formatDate(job.applicationDeadline)),
        _buildDetailItem('Applications Received', job.applicationCount.toString()),
      ],
    );
  }

  Widget _buildRequirementsSection(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Column(
          children: job.requirements.map((requirement) => 
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text(requirement)),
                ],
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildResponsibilitiesSection(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responsibilities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Column(
          children: job.responsibilities.map((responsibility) => 
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text(responsibility)),
                ],
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: job.benefits.map((benefit) => Chip(
            label: Text(benefit),
            backgroundColor: Colors.green[50],
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildApplicationInstructions(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Apply',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          job.applicationInstructions.isNotEmpty 
              ? job.applicationInstructions
              : 'Click the "Apply Now" button below to submit your application.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        if (job.contactEmail.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            'Contact: ${job.contactEmail}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildApplyButton(JobModel job, BuildContext context, ApplicationProvider applicationProvider) {
    final hasApplied = applicationProvider.applications.any((app) => app.jobId == job.id);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!hasApplied) Expanded(
            child: ElevatedButton(
              onPressed: job.canApply ? () {
                Navigator.pushNamed(
                  context,
                  RouteNames.applicationForm,
                  arguments: job,
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                job.canApply ? 'Apply Now' : 'Application Closed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ) else Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Navigate to application status
              },
              child: Text(
                'Application Submitted',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Share job functionality
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}