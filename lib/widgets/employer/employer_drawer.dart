import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/route_names.dart';

class EmployerDrawer extends StatelessWidget {
  const EmployerDrawer({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    Widget buildDrawerItem({
      required IconData icon,
      required String title,
      required String routeName,
      bool isLogout = false,
    }) {
      final bool isSelected = currentRoute == routeName;
      final Color iconColor = isSelected ? Colors.white : Colors.blueAccent;
      final Color textColor = isSelected ? Colors.white : Colors.black87;
      final Color? tileColor = isSelected ? Colors.blueAccent : null;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          tileColor: tileColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () {
            if (isLogout) {
              _handleLogout(context);
            } else if (!isSelected) {
              Navigator.pushNamed(context, routeName);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      );
    }

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blueAccent, Color(0xFF1976D2)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Employer Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your jobs and profile',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              routeName: RouteNames.dashboard,
            ),
            buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              routeName: RouteNames.employerProfile,
            ),
            buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notifications',
              routeName: RouteNames.employerNotifications,
            ),
            buildDrawerItem(
              icon: Icons.settings,
              title: 'Account Settings',
              routeName: RouteNames.employerAccountSettings,
            ),
            buildDrawerItem(
              icon: Icons.help,
              title: 'Support/Help',
              routeName: RouteNames.employerSupportHelp,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(thickness: 1, color: Colors.black12),
            ),
            buildDrawerItem(
              icon: Icons.post_add,
              title: 'Post Job',
              routeName: RouteNames.postJob,
            ),
            buildDrawerItem(
              icon: Icons.work,
              title: 'My Jobs',
              routeName: RouteNames.myJobs,
            ),
            buildDrawerItem(
              icon: Icons.group,
              title: 'Employee Jobs',
              routeName: RouteNames.employeeJobs,
            ),
            buildDrawerItem(
              icon: Icons.analytics,
              title: 'Analytics',
              routeName: RouteNames.employerAnalytics,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(thickness: 1, color: Colors.black12),
            ),
            buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              routeName: '',
              isLogout: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
