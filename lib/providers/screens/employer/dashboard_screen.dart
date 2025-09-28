import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../../core/route_names.dart';
import './employer_applications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool isLoading = true;
  String? error;
  
  // Dashboard data
  int totalJobs = 0;
  int totalApplications = 0;
  int activeCandidates = 0;
  int recentHires = 0;
  List<Map<String, dynamic>> recentActivity = [];
  Map<String, dynamic>? employerData;
  
  // Chart data
  List<FlSpot> applicationSpots = [];
  List<BarChartGroupData> departmentData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Load employer profile
      final employerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (employerDoc.exists) {
        employerData = employerDoc.data();
      }

      // Load jobs data
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('employerId', isEqualTo: currentUser.uid)
          .get();
      
      totalJobs = jobsSnapshot.docs.length;

      // Load applications data
      List<Map<String, dynamic>> allApplications = [];
      int activeCount = 0;
      int hiredCount = 0;
      
      for (var jobDoc in jobsSnapshot.docs) {
        final applicationsSnapshot = await FirebaseFirestore.instance
            .collection('applications')
            .where('jobId', isEqualTo: jobDoc.id)
            .orderBy('appliedAt', descending: true)
            .get();
        
        for (var appDoc in applicationsSnapshot.docs) {
          final appData = appDoc.data();
          appData['id'] = appDoc.id;
          appData['jobTitle'] = jobDoc.data()['title'] ?? 'Unknown Job';
          
          // Get applicant name
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(appData['applicantId'])
                .get();
            if (userDoc.exists) {
              appData['applicantName'] = userDoc.data()!['fullName'] ?? 'Unknown Applicant';
            }
          } catch (e) {
            appData['applicantName'] = 'Unknown Applicant';
          }
          
          allApplications.add(appData);
          
          final status = appData['status']?.toString().toLowerCase() ?? 'applied';
          if (status == 'applied' || status == 'approved') {
            activeCount++;
          } else if (status == 'hired') {
            hiredCount++;
          }
        }
      }

      totalApplications = allApplications.length;
      activeCandidates = activeCount;
      recentHires = hiredCount;

      // Prepare recent activity (last 5 applications)
      recentActivity = allApplications.take(5).toList();

      // Generate chart data
      _generateChartData(allApplications);

      setState(() {
        isLoading = false;
      });

      _animationController.forward();

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _generateChartData(List<Map<String, dynamic>> applications) {
    // Generate application timeline data (last 7 days)
    final now = DateTime.now();
    final applicationCounts = List.filled(7, 0);
    
    for (final app in applications) {
      final appliedAt = (app['appliedAt'] as Timestamp?)?.toDate();
      if (appliedAt != null) {
        final daysDiff = now.difference(appliedAt).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          applicationCounts[6 - daysDiff]++;
        }
      }
    }
    
    applicationSpots = applicationCounts
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
        .toList();

    // Generate department data (mock data for demonstration)
    final departments = ['IT', 'HR', 'Design', 'Sales', 'Finance'];
    departmentData = departments.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: (totalJobs / departments.length + entry.key * 2).toDouble(),
            color: const Color(0xFF1a73e8),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  void _navigate(BuildContext context, String route, {dynamic arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1a73e8),
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Welcome back, ${employerData?['fullName']?.split(' ').first ?? 'Employer'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 230),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 51),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, size: 20),
            ),
            onPressed: () => _navigate(context, RouteNames.employerNotifications),
            tooltip: 'Notifications',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _navigate(context, RouteNames.employerProfile),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 51),
                shape: BoxShape.circle,
                image: employerData?['profilePicture']?.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(employerData!['profilePicture']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: employerData?['profilePicture']?.isEmpty != false
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ),
      ],
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
              'Loading dashboard...',
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
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFF1a73e8),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewSection(),
                const SizedBox(height: 32),
                _buildQuickActionsSection(context),
                const SizedBox(height: 32),
                _buildRecentActivitySection(),
                const SizedBox(height: 32),
                _buildAnalyticsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _DashboardCard(
              title: 'Total Jobs',
              value: totalJobs.toString(),
              icon: Icons.work_outline,
              color: const Color(0xFF1a73e8),
              delay: 0,
            ),
            _DashboardCard(
              title: 'Applications',
              value: totalApplications.toString(),
              icon: Icons.assignment_outlined,
              color: const Color(0xFF1a73e8),
              delay: 200,
            ),
            _DashboardCard(
              title: 'Active Candidates',
              value: activeCandidates.toString(),
              icon: Icons.people_outline,
              color: const Color(0xFF1a73e8),
              delay: 400,
            ),
            _DashboardCard(
              title: 'Recent Hires',
              value: recentHires.toString(),
              icon: Icons.check_circle_outline,
              color: const Color(0xFF1a73e8),
              delay: 600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ActionButton(
                icon: Icons.post_add_outlined,
                label: 'Post New Job',
                onTap: () => _navigate(context, RouteNames.postJob),
              ),
              _ActionButton(
                icon: Icons.work_outline,
                label: 'Manage Jobs',
                onTap: () => _navigate(context, RouteNames.myJobs),
              ),
              _ActionButton(
                icon: Icons.assignment_ind_outlined,
                label: 'Applications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmployerApplicationsScreen(),
                    ),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                onTap: () => _navigate(context, RouteNames.employerAnalytics),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: recentActivity.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Activity will appear here as candidates apply',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: recentActivity.asMap().entries.map((entry) {
                    final index = entry.key;
                    final activity = entry.value;
                    final isLast = index == recentActivity.length - 1;
                    
                    return Column(
                      children: [
                        _ActivityItem(
                          applicantName: activity['applicantName'] ?? 'Unknown Applicant',
                          jobTitle: activity['jobTitle'] ?? 'Unknown Job',
                          timestamp: activity['appliedAt'] as Timestamp?,
                          status: activity['status'] ?? 'applied',
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildApplicationsChart(),
        const SizedBox(height: 24),
        _buildDepartmentChart(),
      ],
    );
  }

  Widget _buildApplicationsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Applications Over Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: applicationSpots.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[value.toInt()],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: applicationSpots,
                          isCurved: true,
                          barWidth: 3,
                          color: const Color(0xFF1a73e8),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFF1a73e8),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF1a73e8).withValues(alpha: 26),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jobs by Department',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: departmentData.isNotEmpty
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (totalJobs + 10).toDouble(),
                      barGroups: departmentData,
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final labels = ['IT', 'HR', 'Design', 'Sales', 'Finance'];
                              if (value.toInt() < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[value.toInt()],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1a73e8),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 51),
                        shape: BoxShape.circle,
                        image: employerData?['profilePicture']?.isNotEmpty == true
                            ? DecorationImage(
                                image: NetworkImage(employerData!['profilePicture']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: employerData?['profilePicture']?.isEmpty != false
                          ? const Icon(Icons.person, color: Colors.white, size: 30)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      employerData?['fullName'] ?? 'Employer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      employerData?['email'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 204),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Employer Dashboard',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 179),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(
                  context,
                  Icons.dashboard_outlined,
                  'Dashboard',
                  () => Navigator.pop(context),
                  isSelected: true,
                ),
                _drawerItem(
                  context,
                  Icons.post_add_outlined,
                  'Post Job',
                  () => _navigate(context, RouteNames.postJob),
                ),
                _drawerItem(
                  context,
                  Icons.work_outline,
                  'My Jobs',
                  () => _navigate(context, RouteNames.myJobs),
                ),
                _drawerItem(
                  context,
                  Icons.people_outline,
                  'Employee Jobs',
                  () => _navigate(context, RouteNames.employeeJobs),
                ),
                _drawerItem(
                  context,
                  Icons.analytics_outlined,
                  'Analytics',
                  () => _navigate(context, RouteNames.employerAnalytics),
                ),
                _drawerItem(
                  context,
                  Icons.notifications_outlined,
                  'Notifications',
                  () => _navigate(context, RouteNames.employerNotifications),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                _drawerItem(
                  context,
                  Icons.person_outline,
                  'Profile',
                  () => _navigate(context, RouteNames.employerProfile),
                ),
                _drawerItem(
                  context,
                  Icons.settings_outlined,
                  'Account Settings',
                  () => _navigate(context, RouteNames.employerAccountSettings),
                ),
                _drawerItem(
                  context,
                  Icons.help_outline,
                  'Support & Help',
                  () => _navigate(context, RouteNames.employerSupportHelp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1a73e8).withValues(alpha: 26) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF1a73e8).withValues(alpha: 51)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF1a73e8) : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1a73e8) : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 24,
                      ),
                    ),
                    Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scaleByVector3(vm.Vector3.all(_isPressed ? 0.95 : 1.0)),
        decoration: BoxDecoration(
          color: _isPressed 
              ? const Color(0xFF1a73e8).withValues(alpha: 26)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPressed 
                ? const Color(0xFF1a73e8).withValues(alpha: 77)
                : Colors.grey.shade200,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a73e8).withValues(alpha: 26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF1a73e8),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String applicantName;
  final String jobTitle;
  final Timestamp? timestamp;
  final String status;

  const _ActivityItem({
    required this.applicantName,
    required this.jobTitle,
    required this.timestamp,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$applicantName applied for $jobTitle',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Icons.assignment_outlined;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'hired':
        return Icons.celebration_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}