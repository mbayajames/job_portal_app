// lib/widgets/application_history_card.dart
import 'package:flutter/material.dart';
import '../models/application_model.dart';

class ApplicationHistoryCard extends StatelessWidget {
  final Application application;
  final VoidCallback? onViewDetails;
  final VoidCallback? onWithdraw;

  const ApplicationHistoryCard({
    super.key,
    required this.application,
    this.onViewDetails,
    this.onWithdraw,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Colors.blue;
      case 'shortlisted':
        return Colors.orange;
      case 'interview':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      case 'hired':
        return Colors.green;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Icons.send;
      case 'shortlisted':
        return Icons.thumb_up;
      case 'interview':
        return Icons.calendar_today;
      case 'rejected':
        return Icons.cancel;
      case 'hired':
        return Icons.work;
      case 'withdrawn':
        return Icons.undo;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: _getStatusColor(application.status).withValues(alpha: 0.2),
          child: Icon(_getStatusIcon(application.status), color: _getStatusColor(application.status)),
        ),
        title: Text(application.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(application.companyName, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Applied: ${_formatDate(application.appliedDate)}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              if (onViewDetails != null) onViewDetails!();
            } else if (value == 'withdraw') {
              if (onWithdraw != null) onWithdraw!();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            if (application.status.toLowerCase() == 'applied')
              const PopupMenuItem(value: 'withdraw', child: Text('Withdraw')),
          ],
        ),
        onTap: onViewDetails,
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
