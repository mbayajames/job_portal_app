import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class EmployerApplicationsScreen extends StatefulWidget {
  final String? jobId;

  const EmployerApplicationsScreen({super.key, this.jobId});

  @override
  State<EmployerApplicationsScreen> createState() => _EmployerApplicationsScreenState();
}

class _EmployerApplicationsScreenState extends State<EmployerApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger('EmployerApplicationsScreen');
  late TabController _tabController;
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> applications = [];
  String searchQuery = '';
  String selectedFilter = 'All';

  final List<String> statusFilters = ['All', 'Applied', 'Approved', 'Rejected', 'Hired'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            error = 'User not authenticated';
            isLoading = false;
          });
        }
        return;
      }

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('applications')
          .orderBy('appliedAt', descending: true);

      // If specific jobId is provided, filter by it
      if (widget.jobId != null) {
        query = query.where('jobId', isEqualTo: widget.jobId);
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> loadedApplications = [];

      for (var doc in snapshot.docs) {
        final appData = doc.data();
        appData['id'] = doc.id;

        // Get job details
        try {
          final jobDoc = await FirebaseFirestore.instance
              .collection('jobs')
              .doc(appData['jobId'])
              .get();
          
          if (jobDoc.exists) {
            final jobData = jobDoc.data()!;
            // Only include if current user is the employer
            if (jobData['employerId'] == currentUser.uid) {
              appData['jobTitle'] = jobData['title'] ?? 'Unknown Job';
              appData['company'] = jobData['company'] ?? 'Unknown Company';
              
              // Get applicant details
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(appData['applicantId'])
                    .get();
                
                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  appData['applicantName'] = userData['fullName'] ?? 'Unknown Applicant';
                  appData['applicantEmail'] = userData['email'] ?? 'No email';
                  appData['applicantPhone'] = userData['phoneNumber'] ?? 'No phone';
                  appData['applicantPhoto'] = userData['profilePicture'] ?? '';
                }
              } catch (e) {
                appData['applicantName'] = 'Unknown Applicant';
                appData['applicantEmail'] = 'No email';
              }

              loadedApplications.add(appData);
            }
          }
        } catch (e) {
          _logger.severe('Error loading job data', e);
        }
      }

      if (mounted) {
        setState(() {
          applications = loadedApplications;
          isLoading = false;
          error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredApplications {
    List<Map<String, dynamic>> filtered = applications;

    // Filter by status
    if (selectedFilter != 'All') {
      filtered = filtered.where((app) => 
        app['status']?.toString().toLowerCase() == selectedFilter.toLowerCase()).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final name = app['applicantName']?.toString().toLowerCase() ?? '';
        final email = app['applicantEmail']?.toString().toLowerCase() ?? '';
        final job = app['jobTitle']?.toString().toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        
        return name.contains(query) || email.contains(query) || job.contains(query);
      }).toList();
    }

    return filtered;
  }

  Map<String, int> get statusCounts {
    final counts = <String, int>{
      'All': applications.length,
      'Applied': 0,
      'Approved': 0,
      'Rejected': 0,
      'Hired': 0,
    };

    for (final app in applications) {
      final status = app['status']?.toString() ?? 'Applied';
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1a73e8),
        foregroundColor: Colors.white,
        title: const Text(
          'Applications Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh Applications',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            color: const Color(0xFF1a73e8),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by applicant name, email, or job...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Status Filter Chips
                SizedBox(
                  height: 35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: statusFilters.length,
                    itemBuilder: (context, index) {
                      final filter = statusFilters[index];
                      final count = statusCounts[filter] ?? 0;
                      final isSelected = selectedFilter == filter;
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            '$filter ($count)',
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF1a73e8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => selectedFilter = filter);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.white.withValues(alpha: 0.2),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a73e8)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading applications...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Applications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadApplications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    final filteredList = filteredApplications;

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty || selectedFilter != 'All'
                  ? Icons.search_off
                  : Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty || selectedFilter != 'All'
                  ? 'No applications match your filter'
                  : 'No applications yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty || selectedFilter != 'All'
                  ? 'Try adjusting your search or filter criteria'
                  : 'Applications will appear here when job seekers apply',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (searchQuery.isNotEmpty || selectedFilter != 'All')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      selectedFilter = 'All';
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1a73e8),
                    side: const BorderSide(color: Color(0xFF1a73e8)),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: const Color(0xFF1a73e8),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final application = filteredList[index];
          return _buildApplicationCard(application);
        },
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final status = application['status'] ?? 'Applied';
    final appliedAt = application['appliedAt'] as Timestamp?;
    final applicantName = application['applicantName'] ?? 'Unknown Applicant';
    final applicantEmail = application['applicantEmail'] ?? 'No email';
    final jobTitle = application['jobTitle'] ?? 'Unknown Job';
    final applicantPhoto = application['applicantPhoto'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Applicant Photo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                    image: applicantPhoto.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(applicantPhoto),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: applicantPhoto.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 28,
                          color: const Color(0xFF1a73e8),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Applicant Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        applicantEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied for: $jobTitle',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            if (appliedAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Applied ${_formatDate(appliedAt.toDate())}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Action Buttons
            _buildActionButtons(application),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> application) {
    final status = application['status'] ?? 'Applied';
    final applicationId = application['id'];

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showApplicationDetails(application),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1a73e8),
              side: const BorderSide(color: Color(0xFF1a73e8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (status == 'Applied') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateApplicationStatus(applicationId, 'Approved'),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateApplicationStatus(applicationId, 'Rejected'),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ] else if (status == 'Approved') ...[
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _updateApplicationStatus(applicationId, 'Hired'),
              icon: const Icon(Icons.work, size: 18),
              label: const Text('Hire Candidate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ] else if (status == 'Hired') ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, size: 18, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Hired Successfully!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return const Color(0xFF1a73e8);
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'hired':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({
        'status': newStatus,
        'reviewedAt': Timestamp.now(),
      });

      // Update local state
      if (mounted) {
        setState(() {
          final index = applications.indexWhere((app) => app['id'] == applicationId);
          if (index != -1) {
            applications[index]['status'] = newStatus;
          }
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application $newStatus successfully'),
            backgroundColor: _getStatusColor(newStatus),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating application: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                            image: application['applicantPhoto']?.isNotEmpty == true
                                ? DecorationImage(
                                    image: NetworkImage(application['applicantPhoto']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: application['applicantPhoto']?.isEmpty != false
                              ? Icon(
                                  Icons.person,
                                  size: 30,
                                  color: const Color(0xFF1a73e8),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application['applicantName'] ?? 'Unknown Applicant',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                application['jobTitle'] ?? 'Unknown Job',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(application['status'] ?? 'Applied').withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            application['status'] ?? 'Applied',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(application['status'] ?? 'Applied'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Contact Information', [
                        _buildDetailItem('Email', application['applicantEmail'] ?? 'Not provided'),
                        _buildDetailItem('Phone', application['applicantPhone'] ?? 'Not provided'),
                      ]),
                      _buildDetailSection('Application Details', [
                        _buildDetailItem('Job Title', application['jobTitle'] ?? 'Not provided'),
                        _buildDetailItem('Company', application['company'] ?? 'Not provided'),
                        _buildDetailItem('Applied Date', application['appliedAt'] != null 
                            ? _formatDate((application['appliedAt'] as Timestamp).toDate())
                            : 'Not provided'),
                        _buildDetailItem('Status', application['status'] ?? 'Applied'),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}