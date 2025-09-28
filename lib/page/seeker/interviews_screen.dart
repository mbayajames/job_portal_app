import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ For joining interview links
import '../../widgets/sidebar.dart';

class Interview {
  final String position;
  final String type;
  DateTime date;
  String time;
  String status;
  final String link; // Join link

  Interview({
    required this.position,
    required this.type,
    required this.date,
    required this.time,
    required this.status,
    required this.link,
  });
}

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key});

  @override
  State<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen> {
  final List<Interview> _interviews = [
    Interview(
      position: 'Flutter Developer at Tech Corp',
      type: 'Video Interview',
      date: DateTime.now().add(const Duration(days: 2)),
      time: '10:00 AM - 11:00 AM',
      status: 'Scheduled',
      link: 'https://meet.google.com/example1',
    ),
    Interview(
      position: 'Senior Developer at Startup Inc',
      type: 'Phone Screening',
      date: DateTime.now().add(const Duration(days: 5)),
      time: '2:00 PM - 2:30 PM',
      status: 'Scheduled',
      link: 'tel:+1234567890', // Phone call
    ),
    Interview(
      position: 'Mobile Developer at Enterprise Ltd',
      type: 'Technical Interview',
      date: DateTime.now().subtract(const Duration(days: 1)),
      time: 'Completed',
      status: 'Completed',
      link: 'https://meet.google.com/example2',
    ),
  ];

  Future<void> _rescheduleInterview(Interview interview) async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: interview.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null) {
      setState(() {
        interview.date = newDate;
        interview.status = 'Scheduled';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interview rescheduled successfully!')),
        );
      }
    }
  }

  Future<void> _joinInterview(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch interview link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text('Interviews'),
      ),
      body: ListView.builder(
        itemCount: _interviews.length,
        itemBuilder: (context, index) {
          final interview = _interviews[index];
          return _buildInterviewCard(interview);
        },
      ),
    );
  }

  Widget _buildInterviewCard(Interview interview) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              interview.position,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.video_call, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(interview.type),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${interview.date.day}/${interview.date.month}/${interview.date.year}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(interview.time),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: interview.status == 'Scheduled'
                        ? Colors.blue.withAlpha(25)
                        : Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interview.status,
                    style: TextStyle(
                      color: interview.status == 'Scheduled' ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (interview.status == 'Scheduled') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rescheduleInterview(interview),
                      child: const Text('Reschedule'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _joinInterview(interview.link),
                      child: const Text('Join Interview'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
