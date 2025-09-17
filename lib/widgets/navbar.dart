import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/routes.dart';
import '../core/constants.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role ?? 'seeker'; // default fallback

    // Menu items based on role
    List<Map<String, dynamic>> menuItems = [];

    if (role == 'seeker') {
      menuItems = [
        {'title': 'Home', 'route': Routes.home},
        {'title': 'Applications', 'route': Routes.applications},
        {'title': 'Profile', 'route': Routes.profile},
      ];
    } else if (role == 'employer') {
      menuItems = [
        {'title': 'Dashboard', 'route': Routes.dashboard},
        {'title': 'Post Job', 'route': Routes.postJob},
        {'title': 'Applicants', 'route': Routes.applicants},
      ];
    } else if (role == 'admin') {
      menuItems = [
        {'title': 'Manage Users', 'route': Routes.manageUsers},
        {'title': 'Manage Jobs', 'route': Routes.manageJobs},
      ];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop / Tablet
          return AppBar(
            title: const Text(appName),
            actions: menuItems.map((item) {
              return TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, item['route']);
                },
                child: Text(
                  item['title'],
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          );
        } else {
          // Mobile
          return AppBar(
            title: const Text(appName),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              )
            ],
          );
        }
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Drawer for mobile (hamburger menu)
class RoleBasedDrawer extends StatelessWidget {
  const RoleBasedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role ?? 'seeker';

    List<Map<String, dynamic>> menuItems = [];

    if (role == 'seeker') {
      menuItems = [
        {'title': 'Home', 'route': Routes.home},
        {'title': 'Applications', 'route': Routes.applications},
        {'title': 'Profile', 'route': Routes.profile},
      ];
    } else if (role == 'employer') {
      menuItems = [
        {'title': 'Dashboard', 'route': Routes.dashboard},
        {'title': 'Post Job', 'route': Routes.postJob},
        {'title': 'Applicants', 'route': Routes.applicants},
      ];
    } else if (role == 'admin') {
      menuItems = [
        {'title': 'Manage Users', 'route': Routes.manageUsers},
        {'title': 'Manage Jobs', 'route': Routes.manageJobs},
      ];
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: kPrimaryColor),
            child: const Text(appName, style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ...menuItems.map((item) {
            return ListTile(
              title: Text(item['title']),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, item['route']);
              },
            );
          }),
        ],
      ),
    );
  }
}
