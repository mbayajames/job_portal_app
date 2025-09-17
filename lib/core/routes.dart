import 'package:flutter/material.dart';
import '../providers/screens/auth/login_screen.dart';
import '../providers/screens/auth/register_screen.dart';
import '../providers/screens/seeker/home_screen.dart';
import '../providers/screens/employer/dashboard_screen.dart';

class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String applications = '/applications';
  static const String profile = '/profile';
  static const String postJob = '/post-job';
  static const String applicants = '/applicants';
  static const String manageUsers = '/manage-users';
  static const String manageJobs = '/manage-jobs';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case applications:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Applications Screen - Coming Soon")),
          ),
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Profile Screen - Coming Soon")),
          ),
        );
      case postJob:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Post Job Screen - Coming Soon")),
          ),
        );
      case applicants:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Applicants Screen - Coming Soon")),
          ),
        );
      case manageUsers:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Manage Users Screen - Coming Soon")),
          ),
        );
      case manageJobs:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Manage Jobs Screen - Coming Soon")),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Route not found")),
          ),
        );
    }
  }
}
