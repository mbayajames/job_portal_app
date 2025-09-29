import 'package:flutter/material.dart';
import '../models/saved_job_model.dart';

class SavedJobCard extends StatefulWidget {
  final SavedJob savedJob;
  final VoidCallback onUnsaved;
  final VoidCallback onApply;
  final VoidCallback? onViewDetails;
  final bool isApplied;

  const SavedJobCard({
    super.key,
    required this.savedJob,
    required this.onUnsaved,
    required this.onApply,
    this.onViewDetails,
    this.isApplied = false,
  });

  @override
  State<SavedJobCard> createState() => _SavedJobCardState();
}

class _SavedJobCardState extends State<SavedJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bookmarkAnimation;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _bookmarkAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCardTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    if (widget.onViewDetails != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onViewDetails!();
      });
    }
  }

  void _handleBookmarkTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    _showUnsaveDialog();
  }

  void _showUnsaveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Remove from Saved',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Remove ${widget.savedJob.jobDetails.title} from your saved jobs?',
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
                widget.onUnsaved();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.savedJob.jobDetails;
    final daysSaved = DateTime.now().difference(widget.savedJob.savedAt).inDays;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF1a73e8).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleCardTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Logo
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          image: job.companyLogo != null
                              ? DecorationImage(
                                  image: NetworkImage(job.companyLogo!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: job.companyLogo == null
                            ? Icon(
                                Icons.business,
                                color: const Color(0xFF1a73e8),
                                size: 28,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Job Title and Company
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              job.company,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bookmark Button
                      ScaleTransition(
                        scale: _bookmarkAnimation,
                        child: GestureDetector(
                          onTap: _handleBookmarkTap,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bookmark,
                              color: Color(0xFF1a73e8),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Job Details Row
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        icon: Icons.location_on_outlined,
                        text: job.isRemote ? 'Remote' : job.location,
                      ),
                      _buildInfoChip(
                        icon: Icons.work_outline,
                        text: job.type,
                      ),
                      _buildInfoChip(
                        icon: Icons.attach_money,
                        text: '\${(job.salary / 1000).toStringAsFixed(0)}K/year',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Job Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          job.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          maxLines: _showFullDescription ? null : 3,
                          overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                        ),
                        if (job.description.length > 150)
                          GestureDetector(
                            onTap: () => setState(() => _showFullDescription = !_showFullDescription),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _showFullDescription ? 'Show less' : 'Show more',
                                style: const TextStyle(
                                  color: Color(0xFF1a73e8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Requirements Preview
                  if (job.requirements.isNotEmpty) ...[
                    Text(
                      'Key Requirements',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...job.requirements.take(3).map((requirement) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 8),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1a73e8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              requirement,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (job.requirements.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${job.requirements.length - 3} more requirements',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  // Saved Info and Notes
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a73e8).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1a73e8).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark_outlined,
                          size: 16,
                          color: const Color(0xFF1a73e8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Saved $daysSaved ${daysSaved == 1 ? 'day' : 'days'} ago',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF1a73e8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.savedJob.notes != null && widget.savedJob.notes!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.note_outlined,
                            size: 14,
                            color: const Color(0xFF1a73e8),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.savedJob.notes != null && widget.savedJob.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.savedJob.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: widget.isApplied ? null : widget.onApply,
                          icon: Icon(
                            widget.isApplied ? Icons.check : Icons.send,
                            size: 18,
                          ),
                          label: Text(
                            widget.isApplied ? 'Applied' : 'Apply Now',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isApplied 
                                ? Colors.green 
                                : const Color(0xFF1a73e8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onViewDetails,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text(
                            'Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1a73e8),
                            side: const BorderSide(color: Color(0xFF1a73e8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}