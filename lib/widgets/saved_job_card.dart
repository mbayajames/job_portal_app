import 'package:flutter/material.dart';
import '../models/saved_job_model.dart';

class SavedJobCard extends StatelessWidget {
  final SavedJob savedJob;
  final VoidCallback onUnsaved;
  final VoidCallback onApply;

  const SavedJobCard({
    super.key,
    required this.savedJob,
    required this.onUnsaved,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    savedJob.jobDetails.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.blue),
                  onPressed: onUnsaved,
                ),
              ],
            ),
            Text(
              savedJob.jobDetails.company,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(savedJob.jobDetails.location),
                const SizedBox(width: 16),
                Icon(Icons.work, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(savedJob.jobDetails.type),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('\$${savedJob.jobDetails.salary.toStringAsFixed(0)}/year'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              savedJob.jobDetails.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApply,
                    child: const Text('Apply Now'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // Show job details
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}