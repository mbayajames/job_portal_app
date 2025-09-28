// lib/screens/seeker/application_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/application_model.dart';
import '../../providers/application_provider.dart';
import '../../widgets/sidebar.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final Application? application;
  final String? applicationId;
  final String? jobTitle;

  const ApplicationDetailsScreen({
    super.key,
    this.application,
    this.applicationId,
    this.jobTitle,
  });

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  Application? _application;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<ApplicationProvider>(context, listen: false);

    try {
      // Use passed application first
      if (widget.application != null) {
        _application = widget.application;
      } 
      // Else try to get from local cache
      else if (widget.applicationId != null) {
        _application = provider.getApplicationById(widget.applicationId!);

        // If still null, fetch all applications from backend
        if (_application == null) {
          await provider.loadApplications();
          _application = provider.getApplicationById(widget.applicationId!);
        }
      }

      if (_application == null) {
        _showError('Application not found.');
      }
    } catch (e) {
      _showError('Failed to load application: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _withdrawApplication() async {
    if (_application == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text('Are you sure you want to withdraw this application? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Withdraw', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        final provider = Provider.of<ApplicationProvider>(context, listen: false);
        await provider.withdrawApplication(_application!.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application withdrawn successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        _showError('Failed to withdraw application: $e');
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied': return Colors.blue;
      case 'shortlisted': return Colors.orange;
      case 'interview': return Colors.purple;
      case 'rejected': return Colors.red;
      case 'hired': return Colors.green;
      case 'withdrawn': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'applied': return Icons.send;
      case 'shortlisted': return Icons.thumb_up;
      case 'interview': return Icons.calendar_today;
      case 'rejected': return Icons.cancel;
      case 'hired': return Icons.work;
      case 'withdrawn': return Icons.undo;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      appBar: AppBar(
        title: Text(widget.jobTitle ?? 'Application Details'),
        actions: [
          if (_application?.status.toLowerCase() == 'applied')
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _withdrawApplication,
              tooltip: 'Withdraw Application',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplication,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_application == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Application not found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadApplication, child: const Text('Try Again')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 20),
          _buildTimelineSection(),
          const SizedBox(height: 20),
          _buildJobDetailsSection(),
          const SizedBox(height: 20),
          _buildApplicationContentSection(),
          const SizedBox(height: 20),
          if (_application!.status.toLowerCase() == 'applied') _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _getStatusColor(_application!.status).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_getStatusIcon(_application!.status), color: _getStatusColor(_application!.status), size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Application Status', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  Text(
                    _application!.status.toUpperCase(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getStatusColor(_application!.status)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildTimelineItem('Applied', _application!.appliedDate, Icons.send, Colors.blue),
        if (_application!.updatedDate != null)
          _buildTimelineItem('Updated', _application!.updatedDate!, Icons.update, Colors.orange),
      ],
    );
  }

  Widget _buildTimelineItem(String title, DateTime date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_formatDate(date), style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Job Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_application!.jobTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_application!.companyName, style: const TextStyle(color: Colors.grey)),
                if (_application!.location.isNotEmpty) Text('Location: ${_application!.location}'),
                if (_application!.salary > 0) Text('Salary: \$${_application!.salary.toStringAsFixed(0)}/year'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Application Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cover Letter', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_application!.coverLetter.isNotEmpty ? _application!.coverLetter : 'No cover letter provided',
                    style: TextStyle(color: _application!.coverLetter.isEmpty ? Colors.grey : null)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _withdrawApplication,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Withdraw Application'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _showUpdateDialog,
            child: const Text('Update Application'),
          ),
        ),
      ],
    );
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Application'),
        content: const Text('Contact the employer to request application updates.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
