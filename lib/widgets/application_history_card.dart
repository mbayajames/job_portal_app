import 'package:flutter/material.dart';

class Application {
  final String id;
  final String jobTitle;
  final String companyName;
  final String status;
  final DateTime appliedDate;
  final String? jobLocation;
  final String? jobType;
  final String? salaryRange;
  final String? applicationNotes;

  Application({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.appliedDate,
    this.jobLocation,
    this.jobType,
    this.salaryRange,
    this.applicationNotes,
  });
}

class ApplicationHistoryCard extends StatefulWidget {
  final Application application;
  final VoidCallback? onViewDetails;
  final VoidCallback? onWithdraw;
  final VoidCallback? onReapply;

  const ApplicationHistoryCard({
    super.key,
    required this.application,
    this.onViewDetails,
    this.onWithdraw,
    this.onReapply,
  });

  @override
  State<ApplicationHistoryCard> createState() => _ApplicationHistoryCardState();
}

class _ApplicationHistoryCardState extends State<ApplicationHistoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return const Color(0xFF1a73e8);
      case 'under review':
      case 'reviewing':
        return Colors.orange.shade600;
      case 'shortlisted':
        return Colors.purple.shade600;
      case 'interview':
      case 'interview scheduled':
        return Colors.amber.shade700;
      case 'rejected':
        return Colors.red.shade600;
      case 'hired':
      case 'accepted':
        return Colors.green.shade600;
      case 'withdrawn':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Icons.send_outlined;
      case 'under review':
      case 'reviewing':
        return Icons.hourglass_empty_outlined;
      case 'shortlisted':
        return Icons.star_outline;
      case 'interview':
      case 'interview scheduled':
        return Icons.calendar_today_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'hired':
      case 'accepted':
        return Icons.check_circle_outline;
      case 'withdrawn':
        return Icons.undo_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return 'Application submitted successfully';
      case 'under review':
      case 'reviewing':
        return 'Your application is being reviewed';
      case 'shortlisted':
        return 'Congratulations! You\'ve been shortlisted';
      case 'interview':
      case 'interview scheduled':
        return 'Interview scheduled - check your email';
      case 'rejected':
        return 'Application not selected this time';
      case 'hired':
      case 'accepted':
        return 'Congratulations! You got the job';
      case 'withdrawn':
        return 'Application withdrawn by you';
      default:
        return 'Status updated';
    }
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    if (widget.onViewDetails != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onViewDetails!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.application.status);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: statusColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: statusColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _getStatusIcon(widget.application.status),
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Job Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.application.jobTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.application.companyName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (widget.application.jobLocation != null) ...[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.application.jobLocation!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (widget.application.jobType != null) ...[
                                  Icon(
                                    Icons.work_outline,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.application.jobType!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // More Options Menu
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        offset: const Offset(-8, 8),
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              widget.onViewDetails?.call();
                              break;
                            case 'withdraw':
                              _showWithdrawDialog();
                              break;
                            case 'reapply':
                              widget.onReapply?.call();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 12),
                                const Text('View Details'),
                              ],
                            ),
                          ),
                          if (_canWithdraw(widget.application.status))
                            PopupMenuItem(
                              value: 'withdraw',
                              child: Row(
                                children: [
                                  const Icon(Icons.undo_outlined, size: 18, color: Colors.orange),
                                  const SizedBox(width: 12),
                                  const Text('Withdraw'),
                                ],
                              ),
                            ),
                          if (_canReapply(widget.application.status))
                            PopupMenuItem(
                              value: 'reapply',
                              child: Row(
                                children: [
                                  const Icon(Icons.refresh_outlined, size: 18, color: Color(0xFF1a73e8)),
                                  const SizedBox(width: 12),
                                  const Text('Reapply'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Status Badge and Message
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.application.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getStatusMessage(widget.application.status),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Application Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Applied Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(widget.application.appliedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (widget.application.salaryRange != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Salary Range',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.application.salaryRange!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Application Notes (if any)
                  if (widget.application.applicationNotes != null &&
                      widget.application.applicationNotes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a73e8).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1a73e8).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 16,
                                color: const Color(0xFF1a73e8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Application Notes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF1a73e8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.application.applicationNotes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canWithdraw(String status) {
    return ['applied', 'under review', 'reviewing'].contains(status.toLowerCase());
  }

  bool _canReapply(String status) {
    return ['rejected', 'withdrawn'].contains(status.toLowerCase());
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Withdraw Application',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to withdraw your application for ${widget.application.jobTitle} at ${widget.application.companyName}?',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onWithdraw?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} mins ago';
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
}