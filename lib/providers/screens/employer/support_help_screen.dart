import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportHelpScreen extends StatefulWidget {
  const SupportHelpScreen({super.key});

  @override
  State<SupportHelpScreen> createState() => _SupportHelpScreenState();
}

class _SupportHelpScreenState extends State<SupportHelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  final user = FirebaseAuth.instance.currentUser!;

  // FAQs
  final List<Map<String, String>> _faqs = [
    {"q": "How to post a job?", "a": "Go to Dashboard → Post Job and fill in job details."},
    {"q": "How to edit or delete a job?", "a": "Navigate to My Jobs → Select Job → Edit/Delete."},
    {"q": "How to view applicants?", "a": "Go to My Jobs → Select Job → View Applicants."},
    {"q": "How subscription plans work?", "a": "Check Subscription Plans in Account Settings."},
    {"q": "Payment and billing issues?", "a": "Go to Payment History or contact support."},
    {"q": "How to contact support?", "a": "Use this form, email us, or call our support number."},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support / Help'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 FAQs
            const Text("FAQs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._faqs.map((faq) => ExpansionTile(
                  title: Text(faq["q"]!),
                  children: [Padding(padding: const EdgeInsets.all(8.0), child: Text(faq["a"]!))],
                )),
            const SizedBox(height: 20),

            // 🔹 Guides & Tutorials
            const Text("Guides & Tutorials", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const ListTile(
              leading: Icon(Icons.video_library, color: Colors.blueAccent),
              title: Text("Posting a Job (Video Tutorial)"),
            ),
            const ListTile(
              leading: Icon(Icons.video_library, color: Colors.blueAccent),
              title: Text("Reviewing Applicants (Video Tutorial)"),
            ),
            const ListTile(
              leading: Icon(Icons.video_library, color: Colors.blueAccent),
              title: Text("Managing Subscription Plans (Step-by-Step Guide)"),
            ),
            const SizedBox(height: 20),

            // 🔹 Troubleshooting
            const Text("Troubleshooting", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const ListTile(title: Text("❌ Can’t log in")),
            const ListTile(title: Text("❌ Jobs not showing")),
            const ListTile(title: Text("❌ Applicants not visible")),
            const ListTile(title: Text("❌ Payment failed")),
            const ListTile(title: Text("❌ Notifications not working")),
            const SizedBox(height: 20),

            // 🔹 Policies
            const Text("Policies & Legal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text("📜 Terms of Service"),
              onTap: () => _launchURL("https://yourapp.com/terms"),
            ),
            ListTile(
              title: const Text("🔒 Privacy Policy"),
              onTap: () => _launchURL("https://yourapp.com/privacy"),
            ),
            ListTile(
              title: const Text("💳 Refund Policy"),
              onTap: () => _launchURL("https://yourapp.com/refund"),
            ),
            const SizedBox(height: 20),

            // 🔹 Contact Support
            const Text("Contact Support", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blueAccent),
              title: const Text("Email us at support@yourapp.com"),
              onTap: () => _launchURL("mailto:support@yourapp.com"),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text("Call us: +123 456 7890"),
              onTap: () => _launchURL("tel:+1234567890"),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.orange),
              title: const Text("Live Chat (Coming Soon)"),
            ),
            const SizedBox(height: 20),

            // 🔹 Contact Form
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Subject is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Message is required' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Submit Request', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final requestData = {
      'userId': user.uid,
      'email': user.email,
      'subject': _subjectController.text.trim(),
      'message': _messageController.text.trim(),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('support_requests').add(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support request submitted successfully'), backgroundColor: Colors.green),
        );
      }

      _formKey.currentState!.reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
