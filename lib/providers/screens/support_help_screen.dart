import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/support_service.dart';

class SupportHelpScreen extends StatefulWidget {
  @override
  _SupportHelpScreenState createState() => _SupportHelpScreenState();
}

class _SupportHelpScreenState extends State<SupportHelpScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitTicket(String userId) async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final supportService = SupportService();
      await supportService.submitTicket(
        userId,
        _subjectController.text.trim(),
        _messageController.text.trim(),
      );
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Support ticket submitted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting ticket: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final supportService = SupportService();
    final user = authProvider.user;
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please sign in to access support', style: TextStyle(color: Colors.black))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Support & Help', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit a Support Ticket',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.black),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submitTicket(user.uid),
              child: _isSubmitting
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Submit Ticket'),
            ),
            SizedBox(height: 30),
            Text(
              'Your Tickets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supportService.getTickets(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final tickets = snapshot.data!;
                if (tickets.isEmpty) {
                  return Text('No support tickets', style: TextStyle(color: Colors.black));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      child: ListTile(
                        title: Text(ticket['subject'] ?? 'No subject', style: TextStyle(color: Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ticket['message'] ?? 'No message', style: TextStyle(color: Colors.black54)),
                            Text('Status: ${ticket['status'] ?? 'Open'}', style: TextStyle(color: Colors.black54)),
                            Text(
                              ticket['createdAt'] != null
                                  ? (ticket['createdAt'] as Timestamp).toDate().toString()
                                  : 'Unknown date',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}