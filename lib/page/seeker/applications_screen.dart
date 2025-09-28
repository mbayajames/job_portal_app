import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/job_provider.dart';
import '../../../models/job_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/route_names.dart';
import 'package:logging/logging.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger('ApplicationsScreen');
  late String seekerId;
  late TabController _tabController;

  final List<String> _statusTabs = ['All', 'Applied', 'Accepted', 'Rejected', 'Hired'];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      seekerId = user.uid;
      _tabController = TabController(length: _statusTabs.length, vsync: this);

      // Fetch data after a small delay to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshData();
      });
    } else {
      _logger.severe('No authenticated user found');
      // Optionally redirect to login screen
    }
  }

  Future<void> _refreshData() async {
    _logger.fine('Refreshing data for seeker $seekerId');
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.fetchJobsForApplicants();
    jobProvider.fetchAppliedJobs(seekerId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final jobs = jobProvider.jobsForApplicants;
    final appliedJobsMap = {for (var j in jobProvider.appliedJobs) j['id'] as String: j};

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Applications"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusTabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: jobProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red.shade400, size: 64),
                      const SizedBox(height: 12),
                      Text('Error: ${jobProvider.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _statusTabs
                      .map((status) => _buildJobsList(jobs, appliedJobsMap, status))
                      .toList(),
                ),
    );
  }

  Widget _buildJobsList(
      List<JobModel> jobs, Map<String, dynamic> appliedJobsMap, String status) {
    List<JobModel> filteredJobs = jobs;

    if (status != 'All') {
      filteredJobs = jobs
          .where((job) =>
              appliedJobsMap.containsKey(job.id) &&
              appliedJobsMap[job.id]?['status'].toString().toLowerCase() == status.toLowerCase())
          .toList();
    }

    if (filteredJobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Text(
                  status == 'All' ? 'No jobs available' : 'No $status applications',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          final job = filteredJobs[index];
          final alreadyApplied = appliedJobsMap.containsKey(job.id);
          final applicationData = alreadyApplied ? appliedJobsMap[job.id] : null;
          final applicationStatus = applicationData?['status'] ?? 'Not Applied';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                job.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${job.company} • ${job.location}'),
                  Text('Type: ${job.employmentType}'),
                  Text('Salary: \$${job.salaryRange}'),
                  Text(
                    'Status: $applicationStatus',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(applicationStatus),
                    ),
                  ),
                ],
              ),
              trailing: alreadyApplied
                  ? null
                  : ElevatedButton(
                      onPressed: () async {
                        try {
                          _logger.fine('Applying to job ${job.id} for seeker $seekerId');
                          await Provider.of<JobProvider>(context, listen: false)
                              .applyToJob(job.id, seekerId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Applied successfully")),
                            );
                            await _refreshData();
                          }
                        } catch (e) {
                          _logger.severe('Error applying to job ${job.id}: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                      child: const Text("Apply"),
                    ),
              onTap: () {
                Navigator.pushNamed(context, RouteNames.jobDetails, arguments: job);
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'hired':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}