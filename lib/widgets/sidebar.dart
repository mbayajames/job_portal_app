import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/route_names.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      width: screenWidth * 0.75, // Responsive width (75% of screen)
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context, authService),
          _buildMenuItem(
            context,
            icon: Icons.home,
            title: 'Home',
            route: RouteNames.seekerHome,
          ),
          _buildMenuItem(
            context,
            icon: Icons.search,
            title: 'Job Search',
            route: RouteNames.jobSearch,
          ),
          _buildMenuItem(
            context,
            icon: Icons.business_center,
            title: 'My Applications',
            route: RouteNames.applications,
          ),
          _buildMenuItem(
            context,
            icon: Icons.bookmark,
            title: 'Saved Jobs',
            route: RouteNames.savedJobs,
          ),
          _buildMenuItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            route: RouteNames.profile,
          ),
          _buildMenuItem(
            context,
            icon: Icons.schedule,
            title: 'Interviews',
            route: RouteNames.interviews,
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            route: RouteNames.notifications,
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            route: RouteNames.accountSettings,
          ),
          const Divider(color: Colors.grey),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, AuthService authService) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF3366FF)],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Color(0xFF3366FF),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Job Seeker',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            authService.userId ?? 'User',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF3366FF),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 16),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF1A1A1A)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF3366FF)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Provider.of<AuthService>(context, listen: false).signOut();
                Navigator.pushReplacementNamed(context, RouteNames.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
