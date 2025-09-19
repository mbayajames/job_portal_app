import 'package:flutter/material.dart';

// Auth Screens
import '../providers/screens/auth/login_screen.dart';
import '../providers/screens/auth/register_screen.dart';
import '../providers/screens/auth/forgot_password.dart';

// Job Seeker Screens
import '../providers/screens/seeker/home_screen.dart' show HomeScreen;
import '../providers/screens/seeker/profile_screen.dart';
import '../providers/screens/seeker/notifications_screen.dart';
import '../providers/screens/applicant/application_screen.dart';
import '../providers/screens/applicant/preview_screen.dart';

// Employer Screens
import '../providers/screens/employer/dashboard_screen.dart';
import '../providers/screens/employer/post_job_screen.dart';
import '../providers/screens/employer/employer_applications_screen.dart';

// Admin Screens
import '../providers/screens/admin/manage_users_screen.dart';
import '../providers/screens/admin/manage_jobs_screen.dart';

// Route Names
import '../core/route_names.dart';

class Routes {
  // Auth
  static const String login = RouteNames.login;
  static const String register = RouteNames.register;
  static const String forgotPassword = RouteNames.forgotPassword;

  // Job Seeker
  static const String seekerHome = RouteNames.seekerHome;
  static const String home = RouteNames.home;
  static const String applications = RouteNames.applications;
  static const String profile = RouteNames.profile;
  static const String notifications = RouteNames.notifications;
  static const String jobDetails = RouteNames.jobDetails;
  static const String preview = RouteNames.preview;
  static const String accountSettings = RouteNames.accountSettings;
  static const String paymentHistory = RouteNames.paymentHistory;
  static const String supportHelp = RouteNames.supportHelp;
  static const String about = RouteNames.about;

  // Employer
  static const String dashboard = RouteNames.dashboard;
  static const String postJob = RouteNames.postJob;
  static const String applicants = RouteNames.applicants;

  // Admin
  static const String manageUsers = RouteNames.manageUsers;
  static const String manageJobs = RouteNames.manageJobs;
  static const String adminDashboard = RouteNames.adminDashboard;
  static const String quickApply = RouteNames.quickApply;
  static const String jobs = RouteNames.jobs;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      // Job Seeker
      case seekerHome:
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case applications:
        final jobData = settings.arguments as Map<String, dynamic>?;
        if (jobData != null) {
          return MaterialPageRoute(builder: (_) => ApplicationScreen(jobData: jobData));
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Job data required for application")),
          ),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());
      case preview:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(builder: (_) => PreviewScreen(
            jobId: args['jobId'],
            userData: args['userData'],
            details: args['details'],
            resumeUrl: args['resumeUrl'],
            coverLetterUrl: args['coverLetterUrl'],
            questionAnswers: args['questionAnswers'],
          ));
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Application data required")),
          ),
        );
      case accountSettings:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Account Settings - Coming Soon")),
          ),
        );
      case paymentHistory:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Payment History - Coming Soon")),
          ),
        );
      case supportHelp:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Support & Help - Coming Soon")),
          ),
        );
      case about:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("About - Coming Soon")),
          ),
        );
      case jobDetails:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Job Details Screen - Coming Soon")),
          ),
        );

      // Employer
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case postJob:
        return MaterialPageRoute(builder: (_) => PostJobScreen());
      case applicants:
        final jobId = settings.arguments as String?;
        if (jobId != null) {
          return MaterialPageRoute(builder: (_) => EmployerApplicationsScreen(jobId: jobId));
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Job ID required for applicants")),
          ),
        );

      // Admin
      case manageUsers:
        return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
      case manageJobs:
        return MaterialPageRoute(builder: (_) => const ManageJobsScreen());
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Admin Dashboard - Coming Soon")),
          ),
        );
      case quickApply:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Quick Apply - Coming Soon")),
          ),
        );
      case jobs:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Jobs - Coming Soon")),
          ),
        );

      // Default
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Route not found")),
          ),
        );
    }
  }
}
