import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/application_service.dart';
import '../../../services/job_service.dart';
import '../../../core/routes.dart';

class PreviewScreen extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> details;
  final String resumeUrl;
  final String? coverLetterUrl;
  final Map<String, String> questionAnswers;

  const PreviewScreen({
    super.key,
    required this.jobId,
    required this.userData,
    required this.details,
    required this.resumeUrl,
    this.coverLetterUrl,
    required this.questionAnswers,
  });

  Future<void> _submitApplication(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final applicationService = ApplicationService();
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit application')),
      );
      return;
    }

    try {
      await applicationService.submitApplication(
        userId: user.uid,
        jobId: jobId,
        details: details,
        resumeUrl: resumeUrl,
        coverLetterUrl: coverLetterUrl,
        questionAnswers: questionAnswers,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully')),
        );
        Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobService = JobService();
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Preview', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>?>(
              future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get().then((doc) => doc.data()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final job = snapshot.data!;
                return Card(
                  child: ListTile(
                    title: Text(job['title'] ?? 'No Title', style: const TextStyle(color: Colors.black)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Company: ${job['companyName'] ?? 'N/A'}', style: const TextStyle(color: Colors.black54)),
                        Text('Location: ${job['location'] ?? 'N/A'}', style: const TextStyle(color: Colors.black54)),
                        Text('Salary: ${job['salaryRange'] ?? 'N/A'}', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Applicant Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${userData['fullName'] ?? 'N/A'}', style: const TextStyle(color: Colors.black)),
                    Text('Email: ${userData['email'] ?? 'N/A'}', style: const TextStyle(color: Colors.black54)),
                    Text('Phone: ${userData['phone'] ?? 'N/A'}', style: const TextStyle(color: Colors.black54)),
                    Text('Bio: ${userData['bio'] ?? 'N/A'}', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 10),
                    Text('Experience: ${details['experience'] ?? 'N/A'}', style: const TextStyle(color: Colors.black54)),
                    Text('Skills: ${details['skills'] ?? 'N/A'}', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Documents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Resume', style: TextStyle(color: Colors.black)),
                subtitle: Text(resumeUrl, style: const TextStyle(color: Colors.black54)),
                trailing: const Icon(Icons.description, color: Colors.blue),
              ),
            ),
            if (coverLetterUrl != null)
              Card(
                child: ListTile(
                  title: const Text('Cover Letter', style: TextStyle(color: Colors.black)),
                  subtitle: Text(coverLetterUrl!, style: const TextStyle(color: Colors.black54)),
                  trailing: const Icon(Icons.description, color: Colors.blue),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Question Answers',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: jobService.getJobQuestions(jobId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final questions = snapshot.data!;
                return Column(
                  children: questions.map((q) {
                    final answer = questionAnswers[q['id']] ?? 'N/A';
                    return Card(
                      child: ListTile(
                        title: Text(q['question'] ?? 'No Question', style: const TextStyle(color: Colors.black)),
                        subtitle: Text(answer, style: const TextStyle(color: Colors.black54)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _submitApplication(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Submit Application', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}