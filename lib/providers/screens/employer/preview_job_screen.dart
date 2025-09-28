import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreviewScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const PreviewScreen({super.key, required this.jobData});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetail('Job Title', widget.jobData['title']),
            _buildDetail('Company', widget.jobData['companyName']),
            _buildDetail('Location', widget.jobData['location']),
            _buildDetail('Job Type', widget.jobData['type']),
            _buildDetail('Experience Level', widget.jobData['experienceLevel']),
            _buildDetail('Salary', widget.jobData['salaryRange'] ?? 'Not specified'),
            _buildDetail('Category', widget.jobData['category']),
            _buildDetail(
              'Application Deadline',
              widget.jobData['deadline'] != null
                  ? (widget.jobData['deadline'] as DateTime)
                      .toLocal()
                      .toString()
                      .split(' ')[0]
                  : 'Not specified',
            ),
            _buildDetail('Description', widget.jobData['description']),
            _buildDetail('Skills', (widget.jobData['skills'] as List).join(', ')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _postJob,
                child: const Text('Confirm & Post Job'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<void> _postJob() async {
    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        ...widget.jobData,
        'createdAt': Timestamp.now(),
        'applicationsCount': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job posted successfully')));

        Navigator.popUntil(context, (route) => route.isFirst); // go back to dashboard/home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error posting job: $e')));
      }
    }
  }
}
