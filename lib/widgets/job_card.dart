import 'package:flutter/material.dart';
import '../models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onUnsave;
  final VoidCallback onApply;
  final VoidCallback onViewDetails;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onSave,
    required this.onUnsave,
    required this.onApply,
    required this.onViewDetails,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap ?? onViewDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Title & Save Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Colors.blue : Colors.grey,
                    ),
                    onPressed: isSaved ? onUnsave : onSave,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Company Name
              Text(
                job.company,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),

              // Location & Employment Type
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    job.location.isNotEmpty ? job.location : 'Remote',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.work, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    job.employmentType.isNotEmpty ? job.employmentType : 'Full-time',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Salary & Posted Time
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatSalary(job.salaryRange),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeAgo(job.createdAt),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Job Description Preview
              Text(
                job.description.length > 150
                    ? '${job.description.substring(0, 150)}...'
                    : job.description,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),

              // Industry Tag
              if (job.industry.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    job.industry,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Apply & View Details Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApply,
                      child: const Text('Apply Now'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format salary safely
  String _formatSalary(String salary) {
    try {
      final parsed = double.tryParse(salary) ?? 0;
      return '\$${parsed.toStringAsFixed(0)}/year';
    } catch (_) {
      return '\$0/year';
    }
  }

  // Get relative time ago
  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
