// core/routes.dart
import 'package:flutter/material.dart';
import 'package:job_portal_app/providers/screens/employer/payment_screen.dart'; // Added

// 🔹 Core
import 'route_names.dart';

// 🔹 Models
import '../models/job_model.dart';
import '../models/application_model.dart';

// 🔹 Auth Screens
import '../providers/screens/auth/login_screen.dart';
import '../providers/screens/auth/register_screen.dart';

// 🔹 Job Seeker Screens
import '../page/seeker/seeker_home_screen.dart';
import '../page/seeker/applications_screen.dart';
import '../page/seeker/application_details_screen.dart';
import '../page/seeker/application_form_screen.dart';
import '../page/seeker/profile_screen.dart';
import '../page/seeker/account_settings_screen.dart';
import '../page/seeker/saved_jobs_screen.dart';
import '../page/seeker/interviews_screen.dart';
import '../providers/screens/common/notifications_screen.dart';

// 🔹 Employer Screens
import '../providers/screens/employer/dashboard_screen.dart';
import '../providers/screens/employer/post_job_screen.dart';
import '../providers/screens/employer/my_jobs_screen.dart';
import '../providers/screens/employer/employer_applications_screen.dart';
import '../providers/screens/employer/employer_profile_screen.dart';
import '../providers/screens/employer/notifications_screen.dart';
import '../providers/screens/employer/analytics_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // ================= INITIAL & AUTH =================
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // ================= JOB SEEKER =================
      case RouteNames.seekerHome:
        return MaterialPageRoute(builder: (_) => const SeekerHomeScreen());
      case RouteNames.applications:
        return MaterialPageRoute(builder: (_) => const ApplicationsScreen());
      case RouteNames.applicationDetails:
        if (args is ApplicationDetailsArguments) {
          return MaterialPageRoute(
            builder: (_) => ApplicationDetailsScreen(
              applicationId: args.applicationId,
              jobTitle: args.jobTitle,
            ),
          );
        } else if (args is Application) {
          return MaterialPageRoute(
            builder: (_) => ApplicationDetailsScreen(application: args),
          );
        } else if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ApplicationDetailsScreen(applicationId: args),
          );
        }
        return _errorRoute(
            "Invalid arguments for applicationDetails. Expected ApplicationDetailsArguments, Application, or String");
      case RouteNames.applicationForm:
        return _buildApplicationFormRoute(args);
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case RouteNames.accountSettings:
        return MaterialPageRoute(builder: (_) => const AccountSettingsScreen());
      case RouteNames.savedJobs:
        return MaterialPageRoute(builder: (_) => const SavedJobsScreen());
      case RouteNames.notifications:
        return MaterialPageRoute(
            builder: (_) => const NotificationsScreen(role: "seeker"));
      case RouteNames.interviews:
        return MaterialPageRoute(builder: (_) => const InterviewsScreen());

      // ================= EMPLOYER =================
      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case RouteNames.postJob:
        return MaterialPageRoute(builder: (_) => const PostJobScreen());
      case RouteNames.myJobs:
        return MaterialPageRoute(builder: (_) => const MyJobsScreen());
      case RouteNames.applicants:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => EmployerApplicationsScreen(jobId: args),
          );
        } else {
          return _errorRoute(
              "Invalid arguments for applicants. Expected String");
        }
      case RouteNames.employerProfile:
        return MaterialPageRoute(builder: (_) => const EmployerProfileScreen());
      case RouteNames.employerNotifications:
        return MaterialPageRoute(
            builder: (_) => const EmployerNotificationsScreen());
      case RouteNames.paymentScreen: // Added
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => PaymentScreen(
              jobData: args['jobData'] as Map<String, dynamic>,
              onPaymentSuccess: args['onPaymentSuccess'] as VoidCallback,
            ),
          );
        }
        return _errorRoute(
            "Invalid arguments for paymentScreen. Expected Map with jobData and onPaymentSuccess");

      // ================= ANALYTICS =================
      case RouteNames.employerAnalytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());

      // ================= DEFAULT =================
      default:
        return _errorRoute("Route not found: ${settings.name}");
    }
  }
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }

  static Route<dynamic> _buildApplicationFormRoute(dynamic args) {
    if (args is JobModel) {
      return MaterialPageRoute(
        builder: (_) => ApplicationFormScreen(job: args),
      );
    } else if (args is String) {
      return MaterialPageRoute(
        builder: (_) => ApplicationFormScreen(jobId: args),
      );
    } else {
      return _errorRoute("Invalid arguments for applicationForm. Expected JobModel or String");
    }
  }
  // ... (Rest of the file remains unchanged: _buildApplicationFormRoute, _createJobModelFromMap, _createJobModelFromObject, _getProperty, _parseDate, _errorRoute, CustomRouteGenerator, ApplicationDetailsArguments, ApplicationFormArguments, JobDetailsArguments, NavigationHelper)
}

class ApplicationDetailsArguments {
  final String applicationId;
  final String jobTitle;

  ApplicationDetailsArguments({required this.applicationId, required this.jobTitle});
}