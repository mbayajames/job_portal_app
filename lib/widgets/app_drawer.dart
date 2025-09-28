import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../core/route_names.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    final userData = authProvider.currentUserData ?? {};
    final role = authProvider.userRole ?? 'seeker';
    final fullName = profileProvider.fullName ?? userData['fullName'] ?? 'Guest';
    final email = authProvider.user?.email ?? '';
    final profileImageUrl = profileProvider.profileImageUrl;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
              child: profileImageUrl == null
                  ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'G',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a73e8), Color(0xFF4285f4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  text: 'Home',
                  onTap: () => Navigator.pushNamed(context, RouteNames.seekerHome),
                ),
                if (role == 'seeker' || role == 'admin')
                  _buildDrawerItem(
                    icon: Icons.work_outline,
                    text: 'My Applications',
                    onTap: () => Navigator.pushNamed(context, RouteNames.applications),
                  ),
                if (role == 'employer' || role == 'admin')
                  _buildDrawerItem(
                    icon: Icons.business_center,
                    text: 'Post a Job',
                    onTap: () => Navigator.pushNamed(context, RouteNames.postJob),
                  ),
                _buildDrawerItem(
                  icon: Icons.person,
                  text: 'Profile',
                  onTap: () => Navigator.pushNamed(context, RouteNames.profile),
                ),
                _buildDrawerItem(
                  icon: Icons.notifications,
                  text: 'Notifications',
                  onTap: () => Navigator.pushNamed(context, RouteNames.notifications),
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  text: 'Account Settings',
                  onTap: () => Navigator.pushNamed(context, RouteNames.accountSettings),
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  text: 'Logout',
                  onTap: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.login,
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Column(
              children: const [
                Text(
                  'Job Portal App © 2025',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
