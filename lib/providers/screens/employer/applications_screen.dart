import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/job_provider.dart';

class ApplicationsScreen extends StatefulWidget {
  final String jobId;
  final String? jobTitle;

  const ApplicationsScreen({
    super.key,
    required this.jobId,
    this.jobTitle,
  });

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _statusFilters = ['All', 'Applied', 'Approved', 'Rejected', 'Hired'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchApplicationsForJob(widget.jobId);
    });
  }

  Future<void> _refreshApplications() async {
    await context.read<JobProvider>().fetchApplicationsForJob(widget.jobId);
  }

  List<Map<String, dynamic>> _getFilteredApplications(List<Map<String, dynamic>> applications) {
    if (_selectedFilter == 'All') return applications;
    return applications.where((app) => app['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, _) {
        final applications = _getFilteredApplications(jobProvider.jobApplications);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Job Applications', style: TextStyle(fontSize: 18)),
                if (widget.jobTitle != null)
                  Text(
                    widget.jobTitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshApplications,
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Applications (${applications.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _buildStatusSummary(jobProvider.jobApplications),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusFilters.map((filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected ? filter : 'All';
                              });
                            },
                            selectedColor: Colors.blue[100],
                            checkmarkColor: Colors.blue[700],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Applications List
              Expanded(
                child: jobProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : jobProvider.error != null
                        ? _buildErrorWidget(jobProvider.error!)
                        : applications.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _refreshApplications,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: applications.length,
                                  itemBuilder: (context, index) {
                                    final application = applications[index];
                                    return _buildApplicationCard(application, jobProvider);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusSummary(List<Map<String, dynamic>> allApplications) {
    final statusCounts = <String, int>{};
    for (final app in allApplications) {
      final status = app['status'] as String;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8,
      children: statusCounts.entries.map((entry) => Chip(
        label: Text(
          '${entry.key}: ${entry.value}',
          style: const TextStyle(fontSize: 11),
        ),
        backgroundColor: _getStatusColor(entry.key).withValues(alpha: 0.1),
        side: BorderSide(color: _getStatusColor(entry.key)),
      )).toList(),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application, JobProvider jobProvider) {
    final status = application['status'] as String;
    final appliedAt = application['appliedAt']?.toDate();
    final applicantName = application['applicantName'] ?? 'Unknown Applicant';
    final applicantEmail = application['applicantEmail'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                  child: Text(
                    applicantName.isNotEmpty ? applicantName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (applicantEmail.isNotEmpty)
                        Text(
                          applicantEmail,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Application Info
            if (appliedAt != null)
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Applied ${DateFormat('MMM dd, yyyy • hh:mm a').format(appliedAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            
            // Notes (if any)
            if (application['notes'] != null && application['notes'].toString().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        application['notes'].toString(),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            _buildActionButtons(application, jobProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> application, JobProvider jobProvider) {
    final status = application['status'] as String;
    final applicationId = application['id'] as String;

    return Row(
      children: [
        // View Details Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showApplicationDetails(application),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue[300]!),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Status-based Action Buttons
        if (status == 'Applied') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showApproveDialog(applicationId, jobProvider),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showRejectDialog(applicationId, jobProvider),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else if (status == 'Approved') ...[
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _showHireDialog(applicationId, jobProvider),
              icon: const Icon(Icons.work, size: 16),
              label: const Text('Hire Candidate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showRejectDialog(applicationId, jobProvider),
            icon: const Icon(Icons.close),
            color: Colors.red[600],
            tooltip: 'Reject',
          ),
        ] else if (status == 'Rejected') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showReconsiderDialog(applicationId, jobProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reconsider'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange[700],
                side: BorderSide(color: Colors.orange[300]!),
              ),
            ),
          ),
        ] else if (status == 'Hired') ...[
          const Expanded(
            child: Chip(
              avatar: Icon(Icons.celebration, size: 16, color: Colors.white),
              label: Text('Hired!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.purple,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Applied':
        return Colors.blue;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Hired':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading applications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshApplications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'All' 
                  ? 'No applications yet'
                  : 'No $_selectedFilter applications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'Applications will appear here once candidates apply'
                  : 'Try selecting a different filter to see other applications',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Methods
  void _showApplicationDetails(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Application Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Applicant', application['applicantName'] ?? 'Unknown'),
              _buildDetailRow('Email', application['applicantEmail'] ?? 'Not provided'),
              _buildDetailRow('Phone', application['applicantPhone'] ?? 'Not provided'),
              _buildDetailRow('Status', application['status']),
              if (application['appliedAt'] != null)
                _buildDetailRow('Applied At', 
                  DateFormat('MMM dd, yyyy • hh:mm a').format(application['appliedAt'].toDate())),
              if (application['reviewedAt'] != null)
                _buildDetailRow('Reviewed At', 
                  DateFormat('MMM dd, yyyy • hh:mm a').format(application['reviewedAt'].toDate())),
              if (application['notes'] != null && application['notes'].toString().isNotEmpty)
                _buildDetailRow('Notes', application['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(String applicationId, JobProvider jobProvider) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to approve this application?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this decision...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await jobProvider.approveApplication(
                  applicationId,
                  notes: notesController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application approved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error approving application: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String applicationId, JobProvider jobProvider) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this application?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Provide feedback to the candidate...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await jobProvider.rejectApplication(
                  applicationId,
                  notes: notesController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application rejected'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rejecting application: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showHireDialog(String applicationId, JobProvider jobProvider) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hire Candidate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Congratulations! Are you ready to hire this candidate?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Welcome message (optional)',
                hintText: 'Welcome to the team! Next steps are...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await jobProvider.hireApplicant(
                  applicationId,
                  notes: notesController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Candidate hired successfully! 🎉'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error hiring candidate: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Hire Now'),
          ),
        ],
      ),
    );
  }

  void _showReconsiderDialog(String applicationId, JobProvider jobProvider) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reconsider Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Move this application back to "Applied" status?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Reason for reconsideration...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await jobProvider.updateApplicationStatus(
                  applicationId,
                  'Applied',
                  notes: notesController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  _refreshApplications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application moved back to review'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating application: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reconsider'),
          ),
        ],
      ),
    );
  }
}