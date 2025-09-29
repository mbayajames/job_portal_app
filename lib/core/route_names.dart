// lib/core/route_names.dart

class RouteNames {
  // ================= INITIAL & AUTH ROUTES =================
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';

  // ================= JOB SEEKER ROUTES =================
  // Main Tabs & Home
  static const String seekerHome = '/seeker/home';

  // Job Search & Browsing
  static const String jobSearch = '/seeker/job-search';
  static const String browseJobs = '/seeker/jobs/browse';
  static const String jobs = '/seeker/jobs/browse'; // Alias for compatibility
  static const String jobDetails = '/seeker/jobs/details';
  static const String jobPreview = '/seeker/jobs/preview';

  // Applications
  static const String applications = '/seeker/applications';
  static const String myApplications = '/seeker/applications'; // Alias
  static const String applicationHistory = '/seeker/applications/history';
  static const String applicationDetails = '/seeker/application/details';
  static const String applicationForm = '/seeker/application/form';
  static const String applicationPreview = '/seeker/applications/preview';

  // Saved Jobs
  static const String savedJobs = '/seeker/saved-jobs';
  static const String jobActivity = '/seeker/jobs/activity';

  // Profile & Settings
  static const String profile = '/seeker/profile';
  static const String editProfile = '/seeker/profile/edit';
  static const String uploadResume = '/seeker/profile/upload-resume';
  static const String preview = '/seeker/profile/preview';

  // Account Management
  static const String accountSettings = '/seeker/settings';
  static const String notifications = '/seeker/notifications';
  static const String privacySettings = '/seeker/settings/privacy';

  // Interviews
  static const String interviews = '/seeker/interviews';
  static const String interviewDetails = '/seeker/interviews/details';

  // Support
  static const String supportHelp = '/seeker/support';
  static const String about = '/seeker/about';
  static const String contactUs = '/seeker/contact';

  // ================= EMPLOYER ROUTES =================
  // Main Tabs & Dashboard
  static const String dashboard = '/employer/dashboard';
  static const String employerDashboard = '/employer/dashboard'; // alias

  // Job Management
  static const String postJob = '/employer/post-job';
  static const String editJob = '/employer/jobs/edit';
  static const String myJobs = '/employer/my-jobs';
  static const String employeeJobs = '/employer/jobs/employee-jobs'; // alias
  static const String jobApplicants = '/employer/jobs/applicants';
  static const String jobAnalytics = '/employer/jobs/analytics';

  // Applicant Management
  static const String applicants = '/employer/applicants';
  static const String applicantDetails = '/employer/applicants/details';
  static const String applicantProfile = '/employer/applicants/profile';

  // Company & Profile
  static const String employerProfile = '/employer/profile';
  static const String companyProfile = '/employer/profile/company';
  static const String editCompanyProfile = '/employer/profile/company/edit';

  // Employer Settings
  static const String employerAccountSettings = '/employer/settings/account';
  static const String employerNotifications = '/employer/notifications';

  // Employer Support
  static const String employerSupportHelp = '/employer/support';
  static const String employerAnalytics = '/employer/analytics';

  // Payment
  static const String paymentScreen = '/employer/payment';

  // ================= COMMON ROUTES =================
  static const String settings = '/settings';
  static const String notificationsCommon = '/notifications';
  static const String search = '/search';
  static const String filters = '/filters';
  static const String webView = '/webview';

  // ================= ROUTE GROUPS =================
  static const List<String> seekerBottomNavRoutes = [
    seekerHome,
    jobSearch,
    applications,
    savedJobs,
    profile,
  ];

  static const List<String> employerBottomNavRoutes = [
    employerDashboard,
    myJobs,
    applicants,
    employerAnalytics,
    employerProfile,
  ];

  static const List<String> authRoutes = [
    login,
    register,
    forgotPassword,
    resetPassword,
    verifyEmail,
  ];

  static const List<String> publicRoutes = [
    splash,
    onboarding,
    about,
  ];
}

/// Route Helper Methods
class RouteHelper {
  /// Generate route with parameters
  static String jobDetailsWithId(String jobId) =>
      '${RouteNames.jobDetails}?id=$jobId';
  static String applicationDetailsWithId(String applicationId) =>
      '${RouteNames.applicationDetails}?id=$applicationId';
  static String applicantDetailsWithId(String applicantId) =>
      '${RouteNames.applicantDetails}?id=$applicantId';
  static String editJobWithId(String jobId) =>
      '${RouteNames.editJob}?id=$jobId';

  /// Extract parameters from route
  static String? getParameter(String route, String paramName) {
    final uri = Uri.parse(route);
    return uri.queryParameters[paramName];
  }

  /// Check if route belongs to a specific group
  static bool isSeekerRoute(String route) => route.startsWith('/seeker');
  static bool isEmployerRoute(String route) => route.startsWith('/employer');
  static bool isAuthRoute(String route) =>
      route.startsWith('/auth') ||
      route == RouteNames.login ||
      route == RouteNames.register;

  /// Get base route without parameters
  static String getBaseRoute(String fullRoute) =>
      Uri.parse(fullRoute).path;
}

/// Route Transition Names
class RouteTransitions {
  static const String fade = 'fade';
  static const String slide = 'slide';
  static const String scale = 'scale';
  static const String rotation = 'rotation';
  static const String custom = 'custom';
}

/// Route Guards
class RouteGuards {
  static const String auth = 'auth';
  static const String guest = 'guest';
  static const String seeker = 'seeker';
  static const String employer = 'employer';
  static const String verified = 'verified';
}
