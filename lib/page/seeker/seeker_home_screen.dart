import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/job_card.dart';
import '../../models/job_model.dart';
import '../../providers/saved_job_provider.dart';
import '../../providers/job_provider.dart';
import '../../core/route_names.dart';

class SeekerHomeScreen extends StatefulWidget {
  const SeekerHomeScreen({super.key});

  @override
  SeekerHomeScreenState createState() => SeekerHomeScreenState();
}

class SeekerHomeScreenState extends State<SeekerHomeScreen> {
  final _logger = Logger('SeekerHomeScreen');
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;

  final List<String> _filters = ['All', 'Full-time', 'Part-time', 'Remote', 'Contract'];
  final List<String> _sortOptions = ['Newest', 'Salary: High to Low', 'Salary: Low to High', 'Relevance'];

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_debounceSearch);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadJobs(resetPagination: true);
      }
    });
  }

  void _loadJobs({bool loadMore = false, bool resetPagination = false}) async {
    if (_isLoading && !loadMore) return;

    _logger.info('Loading jobs: page=$_currentPage, search="${_searchController.text}", filter=$_selectedFilter, sort=$_selectedSort, loadMore=$loadMore');

    setState(() {
      _isLoading = true;
      if (resetPagination || !loadMore) {
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      await jobProvider.loadJobs(
        page: _currentPage,
        searchQuery: _searchController.text.trim(),
        filter: _selectedFilter == 'All' ? null : _selectedFilter,
        sort: _selectedSort,
      );

      setState(() {
        _hasMore = jobProvider.hasMoreJobs;
        if (loadMore) _currentPage++;
        _isLoading = false;
      });
    } catch (error) {
      _logger.severe('Load jobs error: $error');
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load jobs: $error');
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 100 &&
        !_scrollController.position.outOfRange &&
        _hasMore &&
        !_isLoading) {
      _loadJobs(loadMore: true);
    }
  }

  void _onFilterPressed() {
    _showFilterDialog();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20, color: Color(0xFF1A1A1A)),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Job Type'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters.map((filter) => FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: _selectedFilter == filter ? Colors.white : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: _selectedFilter == filter,
                  selectedColor: const Color(0xFF3366FF),
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? filter : 'All';
                    });
                    Navigator.pop(context);
                    _loadJobs(resetPagination: true);
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Sort By'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: _sortOptions.map((sort) => ListTile(
                    title: Text(
                      sort,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                    ),
                    leading: Icon(
                      _selectedSort == sort ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: const Color(0xFF3366FF),
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () {
                      setState(() {
                        _selectedSort = sort;
                      });
                      Navigator.pop(context);
                      _loadJobs(resetPagination: true);
                    },
                  )).toList(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'All';
                          _selectedSort = 'Newest';
                          _searchController.clear();
                        });
                        Navigator.pop(context);
                        _loadJobs(resetPagination: true);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF1A1A1A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: const Color(0xFF1A1A1A),
                      ),
                      child: const Text(
                        'Reset Filters',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadJobs(resetPagination: true);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF3366FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 3 - 24; // Adjust for padding
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionButton(
                icon: Icons.bookmark_border,
                label: 'Saved',
                color: const Color(0xFF3366FF),
                onTap: () => Navigator.pushNamed(context, RouteNames.savedJobs),
                width: itemWidth,
              ),
              _buildQuickActionButton(
                icon: Icons.history,
                label: 'Applications',
                color: const Color(0xFF3366FF),
                onTap: () => Navigator.pushNamed(context, RouteNames.applications),
                width: itemWidth,
              ),
              _buildQuickActionButton(
                icon: Icons.notifications_none,
                label: 'Alerts',
                color: const Color(0xFF3366FF),
                onTap: _setupJobAlerts,
                width: itemWidth,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF3366FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back! 👋',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover your next career opportunity',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _setupJobAlerts,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final savedJobProvider = Provider.of<SavedJobProvider>(context);

    return Scaffold(
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text(
          'Job Search',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF3366FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, size: 20, color: Colors.white),
            ),
            onPressed: () => _loadJobs(resetPagination: true),
            tooltip: 'Refresh Jobs',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWelcomeHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: JobSearchBar(
              controller: _searchController,
              onChanged: (query) {}, // Handled by listener
              onFilterPressed: _onFilterPressed,
            ),
          ),
          _buildQuickActions(context),
          if (_selectedFilter != 'All' || _searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Active filters: ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_selectedFilter != 'All')
                          _buildFilterChip('Type: $_selectedFilter', () {
                            setState(() => _selectedFilter = 'All');
                            _loadJobs(resetPagination: true);
                          }),
                        if (_searchController.text.isNotEmpty)
                          _buildFilterChip('Search: "${_searchController.text}"', () {
                            _searchController.clear();
                            _loadJobs(resetPagination: true);
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${jobProvider.jobsForApplicants.length} jobs found',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Sort: $_selectedSort',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadJobs(resetPagination: true),
              color: const Color(0xFF3366FF),
              child: jobProvider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${jobProvider.error}',
                            style: const TextStyle(color: Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              jobProvider.clearError();
                              _loadJobs(resetPagination: true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3366FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : jobProvider.jobsForApplicants.isEmpty && !_isLoading
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: jobProvider.jobsForApplicants.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= jobProvider.jobsForApplicants.length) {
                              return _buildLoadingIndicator();
                            }

                            final job = jobProvider.jobsForApplicants[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: JobCard(
                                job: job,
                                isSaved: savedJobProvider.isJobSaved(job.id),
                                onSave: () => savedJobProvider.saveJob(job.id),
                                onUnsave: () {
                                  final savedJob = savedJobProvider.savedJobs
                                      .firstWhere((saved) => saved.jobId == job.id);
                                  savedJobProvider.unsaveJob(savedJob.id);
                                },
                                onApply: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.applicationForm,
                                    arguments: job,
                                  );
                                },
                                onViewDetails: () => _showJobDetails(job),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickApplyDialog,
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Quick Apply to Recommended Jobs',
        child: const Icon(Icons.rocket_launch_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No jobs found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'All';
                _searchController.clear();
              });
              _loadJobs(resetPagination: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3366FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
      ),
      backgroundColor: Colors.white,
      deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF1A1A1A)),
      onDeleted: onDelete,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF3366FF)),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            if (_hasMore) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3366FF)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading more jobs...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ] else ...[
              const Icon(Icons.check_circle, color: Color(0xFF3366FF), size: 32),
              const SizedBox(height: 8),
              Text(
                'All jobs loaded',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showJobDetails(JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobDetailsSheet(job: job),
    );
  }

  void _setupJobAlerts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Set Up Job Alerts',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
        content: const Text(
          'Get notified when new jobs matching your criteria are posted.',
          style: TextStyle(color: Color(0xFF1A1A1A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF1A1A1A))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showErrorSnackbar('Job alerts set up successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3366FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Set Up Alerts'),
          ),
        ],
      ),
    );
  }

  void _showQuickApplyDialog() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final recommendedJobs = jobProvider.jobsForApplicants.take(3).toList();

    if (recommendedJobs.isEmpty) {
      _showErrorSnackbar('No jobs available for quick apply');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Apply 🚀',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apply to recommended jobs with one click',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ...recommendedJobs.map((job) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3366FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work, color: Color(0xFF3366FF)),
                ),
                title: Text(
                  job.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                ),
                subtitle: Text(
                  job.company,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3366FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.applicationForm,
                      arguments: job,
                    );
                  },
                ),
              )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A1A1A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: const Color(0xFF1A1A1A),
                  ),
                  child: const Text('Maybe Later'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JobDetailsSheet extends StatelessWidget {
  final JobModel job;

  const JobDetailsSheet({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.company,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3366FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem(Icons.location_on, 'Location', job.location),
                    _buildDetailItem(Icons.work, 'Type', job.employmentType),
                    _buildDetailItem(Icons.attach_money, 'Salary', job.salaryRange),
                    _buildDetailItem(Icons.star, 'Level', job.experienceLevel),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Job Description'),
              const SizedBox(height: 8),
              Text(
                job.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Requirements'),
              const SizedBox(height: 12),
              ...job.requirements.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 12),
                      child: Icon(Icons.circle, size: 6, color: const Color(0xFF3366FF)),
                    ),
                    Expanded(
                      child: Text(
                        req,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.applicationForm,
                      arguments: job,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3366FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Apply Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3366FF)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}