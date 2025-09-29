import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/job_provider.dart';
import '../../../models/job_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/route_names.dart';
import 'package:logging/logging.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> 
    with TickerProviderStateMixin {
  final Logger _logger = Logger('ApplicationsScreen');
  late String seekerId;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _statusTabs = [
    {'label': 'All', 'icon': Icons.work_outline, 'count': 0},
    {'label': 'Applied', 'icon': Icons.send_outlined, 'count': 0},
    {'label': 'Accepted', 'icon': Icons.check_circle_outline, 'count': 0},
    {'label': 'Rejected', 'icon': Icons.cancel_outlined, 'count': 0},
    {'label': 'Hired', 'icon': Icons.star_outline, 'count': 0},
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      seekerId = user.uid;
      _tabController = TabController(length: _statusTabs.length, vsync: this);
      
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshData();
        _animationController.forward();
      });
    } else {
      _logger.severe('No authenticated user found');
    }
  }

  Future<void> _refreshData() async {
    _logger.fine('Refreshing data for seeker $seekerId');
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.fetchJobsForApplicants();
    jobProvider.fetchAppliedJobs(seekerId);
    _updateTabCounts(jobProvider);
  }

  void _updateTabCounts(JobProvider jobProvider) {
    final appliedJobsMap = {for (var j in jobProvider.appliedJobs) j['id'] as String: j};
    
    setState(() {
      _statusTabs[0]['count'] = jobProvider.jobsForApplicants.length; // All
      _statusTabs[1]['count'] = appliedJobsMap.values.where((app) => 
          app['status']?.toString().toLowerCase() == 'applied').length;
      _statusTabs[2]['count'] = appliedJobsMap.values.where((app) => 
          app['status']?.toString().toLowerCase() == 'accepted').length;
      _statusTabs[3]['count'] = appliedJobsMap.values.where((app) => 
          app['status']?.toString().toLowerCase() == 'rejected').length;
      _statusTabs[4]['count'] = appliedJobsMap.values.where((app) => 
          app['status']?.toString().toLowerCase() == 'hired').length;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final jobs = jobProvider.jobsForApplicants;
    final appliedJobsMap = {for (var j in jobProvider.appliedJobs) j['id'] as String: j};

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'My Applications',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[50]!,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.work_history,
                      size: 40,
                      color: Colors.blue[300],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60.0),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.blue[600],
                    indicatorWeight: 3,
                    labelColor: Colors.blue[600],
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: _statusTabs.map((tab) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab['icon'], size: 18),
                          const SizedBox(width: 6),
                          Text(tab['label']),
                          if (tab['count'] > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${tab['count']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ];
        },
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: jobProvider.isLoading
                ? _buildLoadingState()
                : jobProvider.error != null
                    ? _buildErrorState(jobProvider.error!)
                    : TabBarView(
                        controller: _tabController,
                        children: _statusTabs
                            .map((tab) => _buildJobsList(
                                jobs, 
                                appliedJobsMap, 
                                tab['label']
                            ))
                            .toList(),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading your applications...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
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
              appliedJobsMap[job.id]?['status'].toString().toLowerCase() == 
              status.toLowerCase())
          .toList();
    }

    if (filteredJobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.blue[600],
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              child: _buildEmptyState(status),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.blue[600],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          final job = filteredJobs[index];
          final alreadyApplied = appliedJobsMap.containsKey(job.id);
          final applicationData = alreadyApplied ? appliedJobsMap[job.id] : null;
          final applicationStatus = applicationData?['status'] ?? 'Not Applied';

          return _buildJobCard(job, alreadyApplied, applicationStatus, applicationData);
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    IconData icon;
    String title;
    String subtitle;
    Color iconColor;

    switch (status) {
      case 'Applied':
        icon = Icons.send_outlined;
        title = 'No Applied Applications';
        subtitle = 'Applications you\'ve submitted will appear here';
        iconColor = Colors.orange;
        break;
      case 'Accepted':
        icon = Icons.check_circle_outline;
        title = 'No Accepted Applications';
        subtitle = 'Congratulations will appear here when employers accept your applications';
        iconColor = Colors.green;
        break;
      case 'Rejected':
        icon = Icons.cancel_outlined;
        title = 'No Rejected Applications';
        subtitle = 'Don\'t worry, rejections are part of the journey';
        iconColor = Colors.red;
        break;
      case 'Hired':
        icon = Icons.star_outline;
        title = 'No Hired Applications';
        subtitle = 'Your successful job offers will be shown here';
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.work_outline;
        title = 'No Jobs Available';
        subtitle = 'Check back later for new opportunities';
        iconColor = Colors.grey;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(JobModel job, bool alreadyApplied, String applicationStatus, 
      Map<String, dynamic>? applicationData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(applicationStatus).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, RouteNames.jobDetails, arguments: job);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with job title and status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.company,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusChip(applicationStatus),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Job details
                _buildJobDetailRow(Icons.location_on_outlined, job.location),
                const SizedBox(height: 8),
                _buildJobDetailRow(Icons.work_outline, job.employmentType),
                const SizedBox(height: 8),
                _buildJobDetailRow(Icons.attach_money, '\$${job.salaryRange}'),
                
                if (applicationData != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Applied ${_formatDate(applicationData['appliedDate'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action button
                if (!alreadyApplied) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _applyToJob(job),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Apply Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final backgroundColor = color.withValues(alpha: 0.1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Unknown';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _applyToJob(JobModel job) async {
    try {
      _logger.fine('Applying to job ${job.id} for seeker $seekerId');
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blue[600]),
                const SizedBox(height: 16),
                const Text('Submitting application...'),
              ],
            ),
          ),
        ),
      );

      await Provider.of<JobProvider>(context, listen: false)
          .applyToJob(job.id, seekerId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Applied to ${job.title} successfully!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        await _refreshData();
      }
    } catch (e) {
      _logger.severe('Error applying to job ${job.id}: $e');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error applying: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) _applyToJob(job);
              },
            ),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Colors.orange[600]!;
      case 'accepted':
        return Colors.green[600]!;
      case 'rejected':
        return Colors.red[600]!;
      case 'hired':
        return Colors.blue[600]!;
      case 'pending':
        return Colors.amber[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}