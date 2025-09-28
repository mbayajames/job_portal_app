import 'package:flutter/material.dart';
import '../../core/route_names.dart';

class EmployerDrawer extends StatelessWidget {
  const EmployerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    Widget buildDrawerItem({
      required IconData icon,
      required String title,
      required String routeName,
    }) {
      final bool isSelected = currentRoute == routeName;
      return ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.blueAccent),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        tileColor: isSelected ? Colors.blueAccent : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          if (!isSelected) {
            Navigator.pushNamed(context, routeName);
          } else {
            Navigator.pop(context);
          }
        },
      );
    }

    return Drawer(
      child: Container(
        color: Colors.grey[100],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Employer Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your jobs and profile',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            buildDrawerItem(icon: Icons.dashboard, title: 'Dashboard', routeName: RouteNames.dashboard),
            buildDrawerItem(icon: Icons.person, title: 'Profile', routeName: RouteNames.employerProfile),
            buildDrawerItem(icon: Icons.notifications, title: 'Notifications', routeName: RouteNames.employerNotifications),
            buildDrawerItem(icon: Icons.settings, title: 'Account Settings', routeName: RouteNames.employerAccountSettings),
            buildDrawerItem(icon: Icons.help, title: 'Support/Help', routeName: RouteNames.employerSupportHelp),
            const Divider(thickness: 1),
            buildDrawerItem(icon: Icons.post_add, title: 'Post Job', routeName: RouteNames.postJob),
            buildDrawerItem(icon: Icons.work, title: 'My Jobs', routeName: RouteNames.myJobs),
            buildDrawerItem(icon: Icons.group, title: 'Employee Jobs', routeName: RouteNames.employeeJobs),
            buildDrawerItem(icon: Icons.analytics, title: 'Analytics', routeName: RouteNames.employerAnalytics),
          ],
        ),
      ),
    );
  }
}
