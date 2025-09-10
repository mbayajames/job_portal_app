import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/job_provider.dart';
import '../../widgets/job_card.dart';
import 'create_job_screen.dart';
import '../screens/seeker/job_details_screen.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  final AuthService _authService = AuthService();
  String userName = '';
  bool loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _listenEmployerJobs();
  }

  Future<void> _loadUserName() async {
    final uid = _authService.currentUserId();
    if (uid == null) return;

    final doc = await _authService.getUserDoc(uid);
    if (!mounted) return;

    setState(() {
      userName = doc['name'] ?? '';
      loadingUser = false;
    });
  }

  void _listenEmployerJobs() {
    final jobProvider = context.read<JobProvider>();
    final uid = _authService.currentUserId();
    if (uid == null) return;

    _authService.getEmployerJobsStream(uid).listen((jobs) {
      jobProvider.setJobs(jobs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loadingUser ? "Loading..." : "Welcome, $userName"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateJobScreen()),
          );
        },
      ),
      body: jobProvider.jobs.isEmpty
          ? const Center(child: Text("No jobs posted yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: jobProvider.jobs.length,
              itemBuilder: (context, index) {
                final job = jobProvider.jobs[index];
                return JobCard(
                  job: job,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailsScreen(job: job),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
