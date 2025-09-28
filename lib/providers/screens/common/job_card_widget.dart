// lib/widgets/job_card_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/route_names.dart';
import '../../../models/job_model.dart';
import '../../../providers/profile_provider.dart';

class JobCardWidget extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;
  final VoidCallback? onSave; // Optional external callback

  const JobCardWidget({
    super.key,
    required this.job,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    // Check if job is saved
    final savedJobs = List<String>.from(profileProvider.profileData['savedJobs'] ?? []);
    final isSaved = savedJobs.contains(job.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${job.company} • Posted: ${DateFormat('yyyy-MM-dd').format(job.createdAt)}",
        ),
        trailing: IconButton(
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: isSaved ? Colors.blue : Colors.grey,
          ),
          onPressed: () async {
            final updatedSavedJobs = List<String>.from(savedJobs);

            if (isSaved) {
              updatedSavedJobs.remove(job.id);
            } else {
              updatedSavedJobs.add(job.id);
            }

            // Update ProfileProvider
            await profileProvider.updateProfileInfo({'savedJobs': updatedSavedJobs});

            // Call optional external callback if provided
            if (onSave != null) onSave!();

            // Show snack bar
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSaved ? 'Removed from saved jobs' : 'Added to saved jobs',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        onTap: onTap ??
            () {
              Navigator.pushNamed(
                context,
                RouteNames.jobDetails,
                arguments: job,
              );
            },
      ),
    );
  }
}
