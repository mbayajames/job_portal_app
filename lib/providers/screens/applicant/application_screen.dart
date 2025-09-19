import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../auth_provider.dart';
import '../../../services/job_service.dart';
import '../../../services/application_service.dart';
import '../../../core/routes.dart';

class ApplicationScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const ApplicationScreen({super.key, required this.jobData});

  @override
  _ApplicationScreenState createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  File? _resumeFile;
  File? _coverLetterFile;
  Map<String, String> _questionAnswers = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final jobService = JobService();
    final applicationService = ApplicationService();
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (authProvider.user == null || authProvider.currentUserData?['role'] != 'seeker') {
      return Scaffold(
        body: Center(child: Text('Access restricted to job seekers', style: TextStyle(color: Colors.black))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Job', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: 'Experience (e.g., 5 years)',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _skillsController,
              decoration: InputDecoration(
                labelText: 'Skills (comma-separated)',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Upload Documents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                if (result != null) {
                  setState(() => _resumeFile = File(result.files.single.path!));
                }
              },
              child: Text(_resumeFile == null ? 'Upload Resume' : 'Resume Selected', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                if (result != null) {
                  setState(() => _coverLetterFile = File(result.files.single.path!));
                }
              },
              child: Text(_coverLetterFile == null ? 'Upload Cover Letter (Optional)' : 'Cover Letter Selected', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Text(
              'Job Questions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: jobService.getJobQuestions(widget.jobData['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final questions = snapshot.data!;
                return Column(
                  children: questions.map((q) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: q['question'],
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black),
                        ),
                        onChanged: (value) => _questionAnswers[q['id']] = value,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting || _resumeFile == null
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      try {
                        final resumeUrl = await applicationService.uploadFile(
                          authProvider.user!.uid,
                          _resumeFile!.path,
                          'applications',
                        );
                        String? coverLetterUrl;
                        if (_coverLetterFile != null) {
                          coverLetterUrl = await applicationService.uploadFile(
                            authProvider.user!.uid,
                            _coverLetterFile!.path,
                            'applications',
                          );
                        }
                        final details = {
                          'fullName': authProvider.currentUserData?['fullName'] ?? '',
                          'email': authProvider.currentUserData?['email'] ?? '',
                          'experience': _experienceController.text.trim(),
                          'skills': _skillsController.text.trim(),
                        };
                        if (context.mounted) {
                          Navigator.pushNamed(context, Routes.preview, arguments: {
                            'jobId': widget.jobData['id'],
                            'userData': authProvider.currentUserData ?? {},
                            'details': details,
                            'resumeUrl': resumeUrl!,
                            'coverLetterUrl': coverLetterUrl,
                            'questionAnswers': _questionAnswers,
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error preparing application: $e')),
                          );
                        }
                      } finally {
                        if (context.mounted) setState(() => _isSubmitting = false);
                      }
                    },
              child: _isSubmitting
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Preview Application', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}