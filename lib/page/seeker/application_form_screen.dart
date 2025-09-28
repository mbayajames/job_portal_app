import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../../models/job_model.dart';
import '../../providers/application_provider.dart';
import '../../utils/file_picker_util.dart';
import '../../services/file_upload_service.dart';
import '../../widgets/application_form_field.dart';
import '../../core/route_names.dart';

class ApplicationFormScreen extends StatefulWidget {
  final JobModel? job;     // Direct JobModel
  final String? jobId;     // Or a jobId to fetch

  const ApplicationFormScreen({
    super.key,
    this.job,
    this.jobId,
  });

  @override
  ApplicationFormScreenState createState() => ApplicationFormScreenState();
}

class ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final Logger _logger = Logger('ApplicationFormScreenState');
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();

  final _fileUploadService = FileUploadService();
  String? _resumeUrl;

  bool _isSubmitting = false;
  bool _isLoadingJob = false;

  String? _selectedExperience;
  String? _selectedEducation;

  JobModel? _job; // Holds the job model

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _loadJobIfNeeded();
  }

  void _loadJobIfNeeded() async {
    if (widget.job != null) {
      setState(() => _job = widget.job);
    } else if (widget.jobId != null) {
      setState(() => _isLoadingJob = true);
      try {
        final doc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .get();

        if (doc.exists) {
          setState(() {
            _job = JobModel.fromMap(doc.data()!, doc.id);
          });
        }
      } catch (e) {
        _logger.severe("Error fetching job: $e");
      } finally {
        setState(() => _isLoadingJob = false);
      }
    }
  }

  void _prefillUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            _fullNameController.text = userData['fullName'] ?? '';
            _phoneController.text = userData['phoneNumber'] ?? '';
          }
        }
      } catch (e) {
        _logger.severe('Error fetching user data: $e');
      }
    }
  }

  bool get _isFormValid {
    return _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _resumeUrl != null &&
        _selectedExperience != null &&
        _selectedEducation != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingJob) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_job == null) {
      return const Scaffold(
        body: Center(child: Text("Job not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for ${_job!.title}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application for ${_job!.title} at ${_job!.company}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // Full Name
                ApplicationFormField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Full Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                ApplicationFormField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email is required';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                ApplicationFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Phone number is required';
                    if (val.length < 7) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cover Letter
                TextFormField(
                  controller: _coverLetterController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Cover Letter (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Experience Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedExperience,
                  items: ['0-1 years', '1-3 years', '3-5 years', '5+ years']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedExperience = val),
                  decoration: const InputDecoration(
                    labelText: 'Experience',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null ? 'Please select experience' : null,
                ),
                const SizedBox(height: 16),

                // Education Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedEducation,
                  items: ['High School', 'Diploma', 'Bachelor', 'Master', 'PhD']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedEducation = val),
                  decoration: const InputDecoration(
                    labelText: 'Education',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null ? 'Please select education' : null,
                ),
                const SizedBox(height: 16),

                // Resume Upload Section
                _buildResumeSection(),
                const SizedBox(height: 24),

                // Submit Button
                Consumer<ApplicationProvider>(
                  builder: (context, applicationProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || !_isFormValid
                            ? null
                            : _submitApplication,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Application'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resume'),
        const SizedBox(height: 8),
        _resumeUrl == null
            ? ElevatedButton.icon(
                onPressed: _uploadResume,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Resume'),
              )
            : Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Resume uploaded'),
                  TextButton(
                    onPressed: _uploadResume,
                    child: const Text('Change'),
                  ),
                ],
              ),
      ],
    );
  }

  void _uploadResume() async {
    final file = await FilePickerUtil.pickResume();
    if (file != null) {
      try {
        final url = await _fileUploadService.uploadFile(file);
        if (mounted) {
          setState(() => _resumeUrl = url);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume uploaded successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload resume: $e')),
          );
        }
      }
    }
  }

  void _submitApplication() async {
    if (!_formKey.currentState!.validate() || _job == null) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to apply for jobs')),
        );
        Navigator.pushNamed(context, RouteNames.login);
        return;
      }

      final applicationData = {
        'userId': user.uid,
        'userEmail': user.email,
        'jobId': _job!.id,
        'jobTitle': _job!.title,
        'companyName': _job!.company,
        'status': 'pending',
        'appliedDate': FieldValue.serverTimestamp(),
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'coverLetter': _coverLetterController.text,
        'resumeUrl': _resumeUrl ?? '',
        'experience': _selectedExperience,
        'education': _selectedEducation,
      };

      await FirebaseFirestore.instance
          .collection('applications')
          .add(applicationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }
}
