import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/job_provider.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  const JobApplicantsScreen({required this.jobId, super.key});

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> 
    with TickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Applied', 'Approved', 'Rejected', 'Hired'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Debug: Print the jobId
    print('📋 JobApplicantsScreen initialized with jobId: ${widget.jobId}');
    
    _loadApplications();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadApplications() {
    print('🔄 Loading applications for job: ${widget.jobId}');
    _applicationsFuture = Provider.of<JobProvider>(context, listen: false)
        .fetchApplications(widget.jobId);
    
    // Debug: Check what's returned
    _applicationsFuture.then((apps) {
      print('✅ Successfully loaded ${apps.length} applications');
      if (apps.isEmpty) {
        print('⚠️ No applications found for this job');
        _debugCheckFirestore();
      } else {
        print('📄 Applications:');
        for (var app in apps) {
          print('  - ${app['applicantName']} (${app['status']}) - Applied: ${app['appliedAt']}');
        }
      }
    }).catchError((error) {
      print('❌ Error loading applications: $error');
    });
  }

  // Debug method to check Firestore directly
  Future<void> _debugCheckFirestore() async {
    try {
      print('🔍 Checking Firestore directly for jobId: ${widget.jobId}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: widget.jobId)
          .get();
      
      print('📊 Direct Firestore query found ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ No application documents found in Firestore for this job');
        print('💡 Possible issues:');
        print('   1. Applications may not be created correctly');
        print('   2. JobId mismatch between job and application documents');
        print('   3. Firestore rules blocking read access');
        
        // Check if there are ANY applications in the collection
        final allApps = await FirebaseFirestore.instance
            .collection('applications')
            .limit(5)
            .get();
        
        if (allApps.docs.isNotEmpty) {
          print('\n📋 Sample applications in database (to check structure):');
          for (var doc in allApps.docs) {
            print('  Doc ID: ${doc.id}');
            print('  JobId: ${doc.data()['jobId']}');
            print('  Has appliedAt: ${doc.data().containsKey('appliedAt')}');
            print('  Has appliedDate: ${doc.data().containsKey('appliedDate')}');
            print('  Data: ${doc.data()}');
            print('  ---');
          }
        }
      } else {
        print('📄 Raw application documents:');
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print('  Doc ID: ${doc.id}');
          print('  ApplicantId: ${data['applicantId']}');
          print('  Status: ${data['status']}');
          print('  Has appliedAt: ${data.containsKey('appliedAt')}');
          print('  Has appliedDate: ${data.containsKey('appliedDate')}');
          print('  appliedAt value: ${data['appliedAt']}');
          print('  Full Data: $data');
          print('  ---');
        }
      }
    } catch (e) {
      print('❌ Error checking Firestore: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await Provider.of<JobProvider>(context, listen: false)
          .updateApplicationStatus(applicationId, newStatus);
      
      // Refresh the applications list
      setState(() {
        _loadApplications();
      });

      _showSuccessSnackBar('Application status updated to $newStatus');
    } catch (e) {
      _showErrorSnackBar('Failed to update application status: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<Map<String, dynamic>> _filterApplications(List<Map<String, dynamic>> applications) {
    if (_selectedFilter == 'All') return applications;
    return applications.where((app) => 
        app['status'].toString().toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue[700]!;
      case 'rejected':
        return Colors.red[700]!;
      case 'hired':
        return Colors.green[700]!;
      case 'applied':
      case 'pending':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.thumb_up;
      case 'rejected':
        return Icons.thumb_down;
      case 'hired':
        return Icons.celebration;
      case 'applied':
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _formatApplicationDate(dynamic dateValue) {
    try {
      if (dateValue == null) return 'Date not available';
      
      DateTime date;
      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Date not available';
      }
      
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return 'Date not available';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Job Applicants',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadApplications();
              });
            },
            tooltip: 'Refresh Applications',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugCheckFirestore,
            tooltip: 'Debug Check',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[700] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Applications List
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _applicationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading applications...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.error_outline, size: 64, color: Colors.red[700]),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Failed to Load Applications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _loadApplications();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final applications = snapshot.data ?? [];
                  final filteredApplications = _filterApplications(applications);

                  if (filteredApplications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            applications.isEmpty ? 'No Applicants Yet' : 'No $_selectedFilter Applications',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            applications.isEmpty 
                                ? 'Applications will appear here when candidates apply'
                                : 'Try selecting a different filter',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _debugCheckFirestore,
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Debug Check Firestore'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredApplications.length,
                    itemBuilder: (context, index) {
                      final app = filteredApplications[index];
                      return _buildApplicationCard(app);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final status = app['status'] ?? 'Applied';
    final appliedDate = _formatApplicationDate(app['appliedAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: app['applicantPhoto'] != null
                      ? ClipOval(
                          child: Image.network(
                            app['applicantPhoto'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.person, color: Colors.blue[700]),
                          ),
                        )
                      : Icon(Icons.person, color: Colors.blue[700], size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['applicantName'] ?? app['applicantId'] ?? 'Unknown Applicant',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied on $appliedDate',
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
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Application Details
          if (app['coverLetter'] != null || app['resume'] != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (app['coverLetter'] != null) ...[
                    const Text(
                      'Cover Letter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        app['coverLetter'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (app['resume'] != null) ...[
                    Row(
                      children: [
                        Icon(Icons.description, size: 18, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Resume Attached',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (status.toLowerCase() != 'approved') ...[
                  Expanded(
                    child: _buildStatusButton(
                      label: 'Accept',
                      icon: Icons.thumb_up,
                      color: Colors.blue[700]!,
                      onPressed: () => _updateApplicationStatus(app['id'], 'Approved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (status.toLowerCase() != 'rejected') ...[
                  Expanded(
                    child: _buildStatusButton(
                      label: 'Reject',
                      icon: Icons.thumb_down,
                      color: Colors.red[700]!,
                      onPressed: () => _updateApplicationStatus(app['id'], 'Rejected'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (status.toLowerCase() == 'approved' && status.toLowerCase() != 'hired') ...[
                  Expanded(
                    child: _buildStatusButton(
                      label: 'Hire',
                      icon: Icons.celebration,
                      color: Colors.green[700]!,
                      onPressed: () => _updateApplicationStatus(app['id'], 'Hired'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    );
  }
}