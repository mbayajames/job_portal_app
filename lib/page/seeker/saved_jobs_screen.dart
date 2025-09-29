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

class SavedJobsScreenState extends State<SavedJobsScreen> 
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _listFadeAnimation;
  
  String _searchQuery = '';
  String _sortBy = 'date_saved'; // date_saved, title, company
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSavedJobs();
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _listFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadSavedJobs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<SavedJobProvider>(context, listen: false).loadSavedJobs();
        _headerAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          _listAnimationController.forward();
        });
      }
    });
  }

  List<SavedJob> _getFilteredAndSortedJobs(List<SavedJob> jobs) {
    // Filter by search query
    List<SavedJob> filtered = jobs;
    if (_searchQuery.isNotEmpty) {
      filtered = jobs.where((job) {
        return job.jobDetails.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               job.jobDetails.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               job.jobDetails.location.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort jobs
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.jobDetails.title.compareTo(b.jobDetails.title));
        break;
      case 'company':
        filtered.sort((a, b) => a.jobDetails.company.compareTo(b.jobDetails.company));
        break;
      case 'date_saved':
      default:
        filtered.sort((a, b) => b.savedAt.compareTo(a.savedAt));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const Sidebar(),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _headerFadeAnimation,
              child: SlideTransition(
                position: _headerSlideAnimation,
                child: _buildSearchAndFilter(),
              ),
            ),
          ),
          Consumer<SavedJobProvider>(
            builder: (context, savedJobProvider, child) {
              return FadeTransition(
                opacity: _listFadeAnimation,
                child: _buildBody(savedJobProvider),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1a73e8),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Saved Jobs',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1a73e8),
                const Color(0xFF1a73e8).withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.refresh, size: 20),
          ),
          onPressed: _loadSavedJobs,
          tooltip: 'Refresh',
        ),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sort, size: 20),
          ),
          onSelected: (value) {
            setState(() => _sortBy = value);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'date_saved',
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: _sortBy == 'date_saved' ? const Color(0xFF1a73e8) : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Date Saved',
                    style: TextStyle(
                      color: _sortBy == 'date_saved' ? const Color(0xFF1a73e8) : Colors.black87,
                      fontWeight: _sortBy == 'date_saved' ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (_sortBy == 'date_saved') ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 16, color: Color(0xFF1a73e8)),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: 'title',
              child: Row(
                children: [
                  Icon(
                    Icons.title,
                    size: 18,
                    color: _sortBy == 'title' ? const Color(0xFF1a73e8) : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Job Title',
                    style: TextStyle(
                      color: _sortBy == 'title' ? const Color(0xFF1a73e8) : Colors.black87,
                      fontWeight: _sortBy == 'title' ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (_sortBy == 'title') ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 16, color: Color(0xFF1a73e8)),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: 'company',
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 18,
                    color: _sortBy == 'company' ? const Color(0xFF1a73e8) : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Company',
                    style: TextStyle(
                      color: _sortBy == 'company' ? const Color(0xFF1a73e8) : Colors.black87,
                      fontWeight: _sortBy == 'company' ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (_sortBy == 'company') ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 16, color: Color(0xFF1a73e8)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search saved jobs...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(Icons.search, color: Colors.grey[600], size: 22),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SavedJobProvider savedJobProvider) {
    if (savedJobProvider.isLoading) {
      return SliverFillRemaining(child: _buildLoadingState());
    }

    if (savedJobProvider.error != null) {
      return SliverFillRemaining(child: _buildErrorState(savedJobProvider.error!));
    }

    if (savedJobProvider.savedJobs.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    final filteredJobs = _getFilteredAndSortedJobs(savedJobProvider.savedJobs);

    if (filteredJobs.isEmpty && _searchQuery.isNotEmpty) {
      return SliverFillRemaining(child: _buildNoSearchResultsState());
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildJobsHeader(filteredJobs.length, savedJobProvider.savedJobs.length),
          _buildJobList(filteredJobs),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a73e8)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading your saved jobs...',
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadSavedJobs,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 60,
                color: Color(0xFF1a73e8),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Saved Jobs Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your dream job collection!\nSave jobs that interest you for easy access later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.search, size: 20),
              label: const Text(
                'Browse Jobs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No jobs found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No saved jobs match "$_searchQuery".\nTry a different search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1a73e8),
                side: const BorderSide(color: Color(0xFF1a73e8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsHeader(int filteredCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$filteredCount ${filteredCount == 1 ? 'Job' : 'Jobs'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (_searchQuery.isNotEmpty && filteredCount != totalCount)
                  Text(
                    'Filtered from $totalCount total saved jobs',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Your saved job collection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _getSortLabel(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'title':
        return 'Sorted by title';
      case 'company':
        return 'Sorted by company';
      case 'date_saved':
      default:
        return 'Recently saved';
    }
  }

  Widget _buildJobList(List<SavedJob> jobs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final savedJob = jobs[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: SavedJobCard(
            savedJob: savedJob,
            onUnsaved: () => _showUnsaveDialog(savedJob),
            onApply: () => _applyForJob(savedJob.jobDetails),
            onViewDetails: () => _viewJobDetails(savedJob.jobDetails),
          ),
        );
      },
    );
  }

  void _showUnsaveDialog(SavedJob savedJob) {
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
            'Remove "${savedJob.jobDetails.title}" from your saved jobs?',
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
                Provider.of<SavedJobProvider>(context, listen: false)
                    .unsaveJob(savedJob.id);
                Navigator.of(context).pop();
                
                _showSnackbar(
                  'Job removed from saved list',
                  icon: Icons.check_circle,
                  color: Colors.green,
                );
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

  void _applyForJob(Job job) {
    Navigator.pushNamed(
      context,
      '/application-form',
      arguments: job,
    );
  }

  void _viewJobDetails(Job job) {
    // Navigate to job details screen
    Navigator.pushNamed(
      context,
      '/job-details',
      arguments: job,
    );
  }

  void _showSnackbar(String message, {required IconData icon, required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}