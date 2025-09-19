import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/routes.dart';
import '../../auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Employer Dashboard", style: TextStyle(color: primaryWhite)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: primaryWhite),
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${authProvider.user?.displayName ?? 'Employer'}!",
              style: TextStyle(fontSize: isTablet ? 28 : 22, fontWeight: FontWeight.bold, color: primaryBlack),
            ),
            const SizedBox(height: 20),
            _buildDashboardCard(
              "Post New Job",
              "Create and publish job listings",
              Icons.add,
              () => Navigator.pushNamed(context, Routes.postJob),
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              "View Applications",
              "Review job applications from candidates",
              Icons.people,
              () => Navigator.pushNamed(context, Routes.applicants),
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              "Manage Jobs",
              "Edit or remove your job postings",
              Icons.work,
              () => Navigator.pushNamed(context, Routes.manageJobs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryBlue.withOpacity(0.1),
                child: Icon(icon, color: primaryBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlack),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}