import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/saved_job_model.dart';
import '../../providers/saved_job_provider.dart';
import '../../widgets/saved_job_card.dart';
import '../../widgets/sidebar.dart';

class SavedJobsScreen extends StatefulWidget {
   const SavedJobsScreen({super.key});

   @override
   SavedJobsScreenState createState() => SavedJobsScreenState();
 }

 class SavedJobsScreenState extends State<SavedJobsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
  }

  void _loadSavedJobs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<SavedJobProvider>(context, listen: false).loadSavedJobs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text(
          'Saved Jobs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<SavedJobProvider>(
        builder: (context, savedJobProvider, child) {
          return _buildBody(savedJobProvider);
        },
      ),
    );
  }

  Widget _buildBody(SavedJobProvider savedJobProvider) {
    if (savedJobProvider.isLoading) {
      return _buildLoadingState();
    }

    if (savedJobProvider.error != null) {
      return _buildErrorState(savedJobProvider.error!);
    }

    if (savedJobProvider.savedJobs.isEmpty) {
      return _buildEmptyState();
    }

    return _buildJobList(savedJobProvider);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading your saved jobs...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSavedJobs,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Saved Jobs Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start saving jobs that interest you by clicking the bookmark icon on job listings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/job-listings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Browse Jobs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(SavedJobProvider savedJobProvider) {
    return Column(
      children: [
        // Header with count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bookmark,
                color: Colors.blue[800],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${savedJobProvider.savedJobs.length} ${savedJobProvider.savedJobs.length == 1 ? 'Job' : 'Jobs'} Saved',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        ),
        // Job list
        Expanded(
          child: ListView.separated(
            itemCount: savedJobProvider.savedJobs.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[300],
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final savedJob = savedJobProvider.savedJobs[index];
              return SavedJobCard(
                savedJob: savedJob,
                onUnsaved: () => _unsaveJob(savedJob.id),
                onApply: () => _applyForJob(savedJob.jobDetails),
              );
            },
          ),
        ),
      ],
    );
  }

  void _unsaveJob(String savedJobId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Remove Saved Job',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to remove this job from your saved list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<SavedJobProvider>(context, listen: false)
                    .unsaveJob(savedJobId);
                Navigator.of(context).pop();
                
                // Show snackbar confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Job removed from saved list'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _applyForJob(Job job) {
    Navigator.pushNamed(
      context,
      '/application-form',
      arguments: job,
    );
  }
}