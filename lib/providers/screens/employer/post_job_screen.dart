// providers/screens/employer/post_job_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_portal_app/services/job_service.dart';
import 'package:provider/provider.dart';
import 'package:job_portal_app/providers/payment_provider.dart';
import 'payment_screen.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  String _jobType = 'Full-Time';
  String _experienceLevel = 'Entry';
  String _category = 'IT';
  DateTime? _deadline;
  bool _isSubmitting = false;

  final JobService _jobService = JobService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_titleController, 'Job Title', true),
                  _buildTextField(_companyController, 'Company Name', true),
                  _buildTextField(_locationController, 'Location', true),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Job Type',
                    ['Full-Time', 'Part-Time', 'Contract', 'Internship'],
                    _jobType,
                    (val) => setState(() => _jobType = val!),
                  ),
                  _buildDropdown(
                    'Experience Level',
                    ['Entry', 'Mid', 'Senior'],
                    _experienceLevel,
                    (val) => setState(() => _experienceLevel = val!),
                  ),
                  _buildTextField(_salaryController, 'Salary Range (optional)', false),
                  _buildDropdown(
                    'Category',
                    ['IT', 'Marketing', 'HR', 'Finance'],
                    _category,
                    (val) => setState(() => _category = val!),
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker(),
                  _buildTextField(_descriptionController, 'Job Description', true, maxLines: 5),
                  _buildTextField(_skillsController, 'Required Skills (comma separated)', true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitJob,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Proceed to Payment',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool requiredField,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: (val) {
          if (requiredField && (val == null || val.isEmpty)) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(
      String label, List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            isExpanded: true,
            onChanged: onChanged,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: _pickDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Application Deadline',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          child: Text(
            _deadline == null ? 'Select date' : _deadline!.toLocal().toString().split(' ')[0],
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a deadline')));
      return;
    }

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not authenticated')));
      setState(() => _isSubmitting = false);
      return;
    }

    final jobData = {
      'title': _titleController.text,
      'companyName': _companyController.text,
      'location': _locationController.text,
      'type': _jobType,
      'salaryRange': _salaryController.text,
      'experienceLevel': _experienceLevel,
      'category': _category,
      'deadline': Timestamp.fromDate(_deadline!),
      'description': _descriptionController.text,
      'skills': _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'applicationsCount': 0,
      'employerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            jobData: jobData,
            onPaymentSuccess: () async {
              if (!context.mounted) return;
              try {
                jobData['paymentReference'] =
                    Provider.of<PaymentProvider>(context, listen: false).checkoutRequestId ?? '';
                await _jobService.postJobFromMap(jobData);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Job posted successfully')));
                _formKey.currentState!.reset();
                setState(() {
                  _deadline = null;
                  _jobType = 'Full-Time';
                  _experienceLevel = 'Entry';
                  _category = 'IT';
                });
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error posting job: $e')));
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error navigating to payment: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    super.dispose();
  }
}