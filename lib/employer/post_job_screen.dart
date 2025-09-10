import 'package:flutter/material.dart';
import '../../services/job_service.dart';
import '../../models/job_model.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  bool _isPosting = false;

  Future<void> _postJob() async {
    String title = _titleCtrl.text.trim();
    String desc = _descCtrl.text.trim();
    String location = _locationCtrl.text.trim();
    String company = _companyCtrl.text.trim();
    String? postedBy = _authService.currentUserId();

    if ([title, desc, location, company].any((e) => e.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    if (postedBy == null) return;

    setState(() => _isPosting = true);

    try {
      JobModel job = JobModel(
        id: '',
        title: title,
        description: desc,
        company: company,
        location: location,
        postedBy: postedBy,
        createdAt: DateTime.now(),
      );

      await _jobService.createJob(job);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Job posted successfully!")));
      _titleCtrl.clear();
      _descCtrl.clear();
      _locationCtrl.clear();
      _companyCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post a Job")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Job Title")),
            const SizedBox(height: 15),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: "Job Description"), maxLines: 4),
            const SizedBox(height: 15),
            TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: "Location")),
            const SizedBox(height: 15),
            TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: "Company Name")),
            const SizedBox(height: 20),
            _isPosting
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _postJob,
                      child: const Text("Post Job"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
