import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

// 🔹 Core
import 'core/constants.dart';
import 'core/route_names.dart';
import 'core/routes.dart';

// 🔹 Providers
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/employer_profile_provider.dart';
import 'providers/employer_application_provider.dart';
import 'providers/user_provider.dart';
import 'providers/saved_job_provider.dart';
import 'providers/application_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/settings_provider.dart';
import 'services/auth_service.dart';

// 🔹 Auth Screens
import 'providers/screens/auth/login_screen.dart';
import 'providers/screens/auth/register_screen.dart';
import 'providers/screens/auth/forgot_password.dart'; // ✅ Added

// 🔹 Seeker Screens
import 'page/seeker/seeker_home_screen.dart';
import 'page/seeker/profile_screen.dart';
import 'page/seeker/account_settings_screen.dart';
import 'page/seeker/saved_jobs_screen.dart';
import 'page/seeker/applications_screen.dart';
import 'page/seeker/application_details_screen.dart';
import 'page/seeker/job_details_screen.dart';
import 'page/seeker/interviews_screen.dart';

// 🔹 Common Screens
import 'providers/screens/common/job_listing_screen.dart';
import 'providers/screens/common/notifications_screen.dart';

// 🔹 Employer Screens
import 'providers/screens/employer/my_jobs_screen.dart';

// 🔹 Firebase
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Setup logging
  _setupLogging();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const JobPortalApp());
}

/// Setup logging configuration
void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });
}

class JobPortalApp extends StatelessWidget {
  const JobPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => EmployerProfileProvider()),
        ChangeNotifierProvider(create: (_) => EmployerApplicationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SavedJobProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => authService),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Job Portal App',
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: kPrimaryColor,
            iconTheme: IconThemeData(color: AppColors.background),
            titleTextStyle: TextStyle(
              color: AppColors.background,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        initialRoute: RouteNames.login,
        onGenerateRoute: Routes.generateRoute,
        routes: {
          // ✅ Auth
          RouteNames.login: (context) => const LoginScreen(),
          RouteNames.register: (context) => const RegisterScreen(),
          RouteNames.forgotPassword: (context) =>
              const ForgotPasswordScreen(), // ✅ Added

          // ✅ Seeker
          RouteNames.seekerHome: (context) => const SeekerHomeScreen(),
          RouteNames.profile: (context) => const ProfileScreen(),
          RouteNames.accountSettings: (context) => const AccountSettingsScreen(),
          RouteNames.savedJobs: (context) => const SavedJobsScreen(),
          RouteNames.applications: (context) => const ApplicationsScreen(),
          RouteNames.applicationDetails: (context) =>
              const ApplicationDetailsScreen(),

          // ✅ Jobs
          RouteNames.jobSearch: (context) => const JobListingScreen(),
          RouteNames.jobDetails: (context) => const JobModelDetailsScreen(),

          // ✅ Common
          RouteNames.interviews: (context) => const InterviewsScreen(),
          RouteNames.notifications: (context) => const NotificationsScreen(),

          // ✅ Employer
          RouteNames.myJobs: (context) => const MyJobsScreen(),
        },
      ),
    );
  }
}
