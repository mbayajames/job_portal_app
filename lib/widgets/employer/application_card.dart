import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/application_model.dart';
import '../../../providers/screens/employer/applicant_details_screen.dart';

class ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final Function(String, String)? onStatusUpdate;

  const ApplicationCard({super.key, required this.application, this.onStatusUpdate});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Applied':
      case 'Pending Review':
        return Colors.yellow;
      case 'Reviewed':
        return Colors.blue;
      case 'Interview Scheduled':
        return Colors.blueAccent;
      case 'Offer':
      case 'Hired':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(application.status),
          radius: 12,
        ),
        title: Text(application.applicantName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${application.jobTitle} • ${application.companyName}'),
            Text('Submitted: ${DateFormat.yMMMd().format(application.appliedDate)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            // Handle quick actions
            if (value == 'View Details') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicationDetailsScreen(application: application),
                ),
              );
            } else if (value == 'Shortlist') {
              onStatusUpdate?.call(application.id, 'Shortlisted');
            } else if (value == 'Reject') {
              onStatusUpdate?.call(application.id, 'Rejected');
            } else if (value == 'Schedule Interview') {
              onStatusUpdate?.call(application.id, 'Interview Scheduled');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'View Details', child: Text('View Details')),
            const PopupMenuItem(value: 'Shortlist', child: Text('Shortlist')),
            const PopupMenuItem(value: 'Reject', child: Text('Reject')),
            const PopupMenuItem(value: 'Schedule Interview', child: Text('Schedule Interview')),
          ],
        ),
      ),
    );
  }
}
