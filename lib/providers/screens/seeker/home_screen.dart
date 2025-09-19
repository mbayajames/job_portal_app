import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/routes.dart';
import '../../auth_provider.dart' as local_auth;
import '../../job_provider.dart';
import '../../notification_provider.dart';
import '../../../services/job_service.dart';
import '../../../models/job_model.dart';
import '../applicant/application_screen.dart';
import '../employer/employer_applications_screen.dart';
import '../employer/post_job_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';
  String _selectedJobType = '';
  String _selectedLocation = '';
  String _selectedSalaryRange = '';
  String _sortOption = 'Newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<local_auth.AuthProvider>(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null) {
          return _buildGuestView(context);
        }
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            final role = userData?['role']?.toString().toLowerCase() ?? 'seeker';
            if (role == 'employer') {
              return _buildEmployerView(context, user.uid, userData);
            }
            return _buildSeekerView(context, user, userData ?? {});
          },
        );
      },
    );
  }

  Widget _buildGuestView(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Portal', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, Routes.login),
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, Routes.register),
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context, 'Welcome to Job Portal!', 'Find your dream job or hire top talent.'),
            _buildJobList(context, isGuest: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSeekerView(BuildContext context, User user, Map<String, dynamic> userData) {
    final jobProvider = Provider.of<JobProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Portal', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.bell, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, Routes.notifications),
              ),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${notificationProvider.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.user, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, Routes.profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(context, 'Welcome, ${userData['fullName'] ?? 'User'}!', 'Explore job opportunities below.'),
            const SizedBox(height: 20),
            // Search & Filters
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs by title, company, or keywords',
                prefixIcon: const FaIcon(FontAwesomeIcons.search, color: Colors.blue),
                suffixIcon: IconButton(
                  icon: const FaIcon(FontAwesomeIcons.filter, color: Colors.blue),
                  onPressed: () => _showFilterDialog(context),
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => jobProvider.searchJobs(value),
            ),
            const SizedBox(height: 20),
            // Job Categories
            Text(
              'Job Categories',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['IT', 'Marketing', 'Finance', 'Design', 'Engineering'].map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : '';
                          jobProvider.filterJobs(
                            category: _selectedCategory,
                            jobType: _selectedJobType,
                            location: _selectedLocation,
                            salaryRange: _selectedSalaryRange,
                            sortOption: _sortOption,
                          );
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Trending Jobs
            Text(
              'Trending Jobs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<JobModel>>(
                stream: JobService().getJobsStream(limit: 5),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final jobs = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: jobs.length,
                    itemBuilder: (context, index) => _buildJobCard(context, jobs[index], false, isTablet, user.uid),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Saved Jobs
            Text(
              'Saved Jobs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<JobModel>>(
              stream: JobService().getSavedJobsStream(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final jobs = snapshot.data!;
                if (jobs.isEmpty) {
                  return const Text('No saved jobs', style: TextStyle(color: Colors.black54));
                }
                return Column(
                  children: jobs.map((job) => _buildJobCard(context, job, false, isTablet, user.uid)).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            // Featured Jobs
            Text(
              'Featured Jobs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<JobModel>>(
              stream: jobProvider.jobsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final jobs = snapshot.data!;
                if (jobs.isEmpty) {
                  return const Text('No jobs found', style: TextStyle(color: Colors.black54));
                }
                return Column(
                  children: jobs.map((job) => _buildJobCard(context, job, false, isTablet, user.uid)).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            // Tips Section
            Text(
              'Job Seeker Tips',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Improve Your Resume', style: TextStyle(color: Colors.black)),
                subtitle: const Text('Use action verbs and quantify achievements.', style: TextStyle(color: Colors.black54)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Get Noticed by Employers', style: TextStyle(color: Colors.black)),
                subtitle: const Text('Tailor your applications and network on LinkedIn.', style: TextStyle(color: Colors.black54)),
              ),
            ),
            const SizedBox(height: 20),
            // Announcements/News
            Text(
              'Announcements',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('New Job Postings', style: TextStyle(color: Colors.black)),
                subtitle: const Text('Check out the latest opportunities in IT and Marketing!', style: TextStyle(color: Colors.black54)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Trending Companies', style: TextStyle(color: Colors.black)),
                subtitle: const Text('Tech Corp and Design Studio are hiring now.', style: TextStyle(color: Colors.black54)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.profile),
        backgroundColor: Colors.blue,
        tooltip: 'Update Profile',
        child: const FaIcon(FontAwesomeIcons.user, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigation(context, isEmployer: false),
    );
  }

  Widget _buildEmployerView(BuildContext context, String userId, Map<String, dynamic>? userData) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.user, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, Routes.profile),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.signOutAlt, color: Colors.white),
            onPressed: () => Provider.of<local_auth.AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').where('employerId', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final jobs = snapshot.data!.docs.map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
          return SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context, 'Welcome, ${userData?['fullName'] ?? 'Employer'}!', 'Manage your job postings and applications.'),
                _buildEmployerStats(context, jobs.length),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('applications').where('jobId', isEqualTo: job.id).snapshots(),
                      builder: (context, appSnapshot) {
                        final appCount = appSnapshot.hasData ? appSnapshot.data!.docs.length : 0;
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: isTablet ? 16 : 0),
                          child: ListTile(
                            leading: const FaIcon(FontAwesomeIcons.briefcase, color: Colors.blue),
                            title: Text(job.title, style: const TextStyle(color: Colors.black)),
                            subtitle: Text('Applications: $appCount', style: const TextStyle(color: Colors.black54)),
                            trailing: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, Routes.applicants, arguments: job.id),
                              child: const Text('Manage'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.postJob),
        backgroundColor: Colors.blue,
        tooltip: 'Post New Job',
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigation(context, isEmployer: true),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildJobList(BuildContext context, {bool isGuest = false}) {
    final jobProvider = Provider.of<JobProvider>(context);
    return StreamBuilder<List<JobModel>>(
      stream: isGuest ? JobService().getJobsStream(limit: 10) : jobProvider.jobsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final jobs = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            final isTablet = MediaQuery.of(context).size.width > 600;
            return _buildJobCard(context, job, isGuest, isTablet, isGuest ? '' : FirebaseAuth.instance.currentUser!.uid);
          },
        );
      },
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job, bool isGuest, bool isTablet, String userId) {
    final jobService = JobService();
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: isTablet ? 16 : 0),
      child: ListTile(
        leading: const FaIcon(FontAwesomeIcons.briefcase, color: Colors.blue),
        title: Text(job.title, style: const TextStyle(color: Colors.black)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company: ${job.companyName}', style: const TextStyle(color: Colors.black54)),
            Text('Location: ${job.location}', style: const TextStyle(color: Colors.black54)),
            Text('Type: ${job.jobType}', style: const TextStyle(color: Colors.black54)),
            if (job.salaryRange.isNotEmpty) Text('Salary: ${job.salaryRange}', style: const TextStyle(color: Colors.black54)),
            Text(
              job.description.length > 50 ? '${job.description.substring(0, 50)}...' : job.description,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        trailing: isGuest
            ? ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, Routes.login),
                child: const Text('Sign In to Apply'),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: FaIcon(
                      job.isSaved ? FontAwesomeIcons.bookmark : FontAwesomeIcons.bookmark,
                      color: Colors.blue,
                    ),
                    onPressed: () async {
                      await jobService.toggleSaveJob(userId, job.id);
                      Provider.of<JobProvider>(context, listen: false).notifyListeners();
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, Routes.applications, arguments: job.id),
                    child: const Text('Apply Now'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmployerStats(BuildContext context, int jobCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const FaIcon(FontAwesomeIcons.briefcase, color: Colors.blue, size: 30),
                const SizedBox(height: 8),
                Text('$jobCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                const Text('Active Jobs', style: TextStyle(color: Colors.black54)),
              ],
            ),
            Column(
              children: [
                const FaIcon(FontAwesomeIcons.fileAlt, color: Colors.blue, size: 30),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('applications').snapshots(),
                  builder: (context, snapshot) {
                    final appCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text('$appCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black));
                  },
                ),
                const Text('Total Applications', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, {required bool isEmployer}) {
    return BottomNavigationBar(
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.black54,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, isEmployer ? Routes.dashboard : Routes.seekerHome);
            break;
          case 1:
            Navigator.pushNamed(context, isEmployer ? Routes.postJob : Routes.seekerHome);
            break;
          case 2:
            Navigator.pushNamed(context, isEmployer ? Routes.applicants : Routes.applications);
            break;
          case 3:
            Navigator.pushNamed(context, Routes.profile);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.home), label: 'Home'),
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.briefcase), label: 'Jobs'),
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.fileAlt), label: 'Applications'),
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.user), label: 'Profile'),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Jobs', style: TextStyle(color: Colors.blue)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  hint: const Text('Category'),
                  items: ['IT', 'Marketing', 'Finance', 'Design', 'Engineering']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => _selectedCategory = value ?? '',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedJobType.isEmpty ? null : _selectedJobType,
                  hint: const Text('Job Type'),
                  items: ['Full-time', 'Part-time', 'Internship']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => _selectedJobType = value ?? '',
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(hintText: 'Location'),
                  onChanged: (value) => _selectedLocation = value,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedSalaryRange.isEmpty ? null : _selectedSalaryRange,
                  hint: const Text('Salary Range'),
                  items: ['0-50K', '50K-100K', '100K+']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => _selectedSalaryRange = value ?? '',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _sortOption,
                  hint: const Text('Sort By'),
                  items: ['Newest', 'Salary High to Low', 'Salary Low to High']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => _sortOption = value ?? 'Newest',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = '';
                  _selectedJobType = '';
                  _selectedLocation = '';
                  _selectedSalaryRange = '';
                  _sortOption = 'Newest';
                });
                Provider.of<JobProvider>(context, listen: false).resetFilters();
                Navigator.pop(context);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Provider.of<JobProvider>(context, listen: false).filterJobs(
                  category: _selectedCategory,
                  jobType: _selectedJobType,
                  location: _selectedLocation,
                  salaryRange: _selectedSalaryRange,
                  sortOption: _sortOption,
                );
                Navigator.pop(context);
              },
              child: const Text('Apply', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}