// lib/core/constants.dart
import 'package:flutter/material.dart';

/// App Constants - Centralized configuration for the entire application
class AppConstants {
  // App Information
  static const String appName = 'JobSeeker Pro';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Professional Job Portal Application';

  // API & Backend Configuration
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/user/profile';
  static const String jobsEndpoint = '/jobs';
  static const String applicationsEndpoint = '/applications';
  static const String savedJobsEndpoint = '/saved-jobs';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String applicationsCollection = 'applications';
  static const String companiesCollection = 'companies';
  static const String notificationsCollection = 'notifications';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';
  
  // Default Values
  static const int defaultPageSize = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int otpTimeoutSeconds = 300;
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
}

/// Application Colors - Complete color palette
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF00C853);
  static const Color secondaryDark = Color(0xFF009624);
  static const Color secondaryLight = Color(0xFF5EFC82);
  
  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Gray Scale
  static const Color gray50 = Color(0xFFF8F9FA);
  static const Color gray100 = Color(0xFFF1F3F4);
  static const Color gray200 = Color(0xFFE8EAED);
  static const Color gray300 = Color(0xFFDADCE0);
  static const Color gray400 = Color(0xFFBDC1C6);
  static const Color gray500 = Color(0xFF9AA0A6);
  static const Color gray600 = Color(0xFF80868B);
  static const Color gray700 = Color(0xFF5F6368);
  static const Color gray800 = Color(0xFF3C4043);
  static const Color gray900 = Color(0xFF202124);
  
  // Semantic Colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Status Colors
  static const Color submitted = Color(0xFF2196F3);
  static const Color pending = Color(0xFFFF9800);
  static const Color reviewed = Color(0xFF9C27B0);
  static const Color interview = Color(0xFF00BCD4);
  static const Color offer = Color(0xFF4CAF50);
  static const Color rejected = Color(0xFFF44336);
  static const Color withdrawn = Color(0xFF607D8B);
}

/// Application Text Styles - Typography system
class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.black,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: AppColors.black,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.black,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.black,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.gray800,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.gray800,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.gray700,
  );
  
  static const TextStyle bodyXSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.gray600,
  );
  
  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  
  // Caption & Labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.gray600,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.gray700,
  );
  
  // Dark Theme Variants
  static const TextStyle heading1Dark = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.white,
  );

  static const TextStyle heading2Dark = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: AppColors.white,
  );

  static const TextStyle heading3Dark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.white,
  );

  static const TextStyle heading4Dark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.white,
  );

  static const TextStyle bodyMediumDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.gray200,
  );

  static const TextStyle bodySmallDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.gray300,
  );
}

/// Application Dimensions - Spacing, sizes, and layout constants
class AppDimens {
  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  
  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusRound = 50.0;
  
  // Button Sizes
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 52.0;
  
  // Icon Sizes
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 40.0;
  
  // App Bar
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 2.0;
}

/// Job & Application Related Constants
class JobConstants {
  // Job Types
  static const List<String> jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Remote',
    'Temporary',
    'Freelance'
  ];
  
  // Experience Levels
  static const List<String> experienceLevels = [
    'Entry-level',
    'Mid-level',
    'Senior',
    'Executive',
    'Internship'
  ];
  
  // Industries
  static const List<String> industries = [
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Manufacturing',
    'Retail',
    'Hospitality',
    'Construction',
    'Marketing',
    'Design',
    'Sales',
    'Engineering',
    'Other'
  ];
  
  // Salary Ranges
  static const List<String> salaryRanges = [
    'Under \$20,000',
    '\$20,000 - \$40,000',
    '\$40,000 - \$60,000',
    '\$60,000 - \$80,000',
    '\$80,000 - \$100,000',
    '\$100,000 - \$120,000',
    'Over \$120,000'
  ];
  
  // Work Arrangements
  static const List<String> workArrangements = [
    'On-site',
    'Remote',
    'Hybrid',
    'Flexible'
  ];
}

/// Application Status Constants
class ApplicationStatuses {
  static const String submitted = 'Submitted';
  static const String pending = 'Pending Review';
  static const String reviewed = 'Under Review';
  static const String shortlisted = 'Shortlisted';
  static const String interview = 'Interview Scheduled';
  static const String secondInterview = 'Second Interview';
  static const String finalRound = 'Final Round';
  static const String offer = 'Offer Extended';
  static const String accepted = 'Accepted';
  static const String rejected = 'Rejected';
  static const String withdrawn = 'Withdrawn';
  static const String expired = 'Expired';
  
  static Color getStatusColor(String status) {
    switch (status) {
      case submitted:
        return AppColors.submitted;
      case pending:
      case reviewed:
        return AppColors.pending;
      case shortlisted:
      case interview:
      case secondInterview:
      case finalRound:
        return AppColors.interview;
      case offer:
      case accepted:
        return AppColors.offer;
      case rejected:
      case expired:
        return AppColors.rejected;
      case withdrawn:
        return AppColors.withdrawn;
      default:
        return AppColors.gray500;
    }
  }
  
  static IconData getStatusIcon(String status) {
    switch (status) {
      case submitted:
        return Icons.send;
      case pending:
      case reviewed:
        return Icons.access_time;
      case shortlisted:
        return Icons.star;
      case interview:
      case secondInterview:
      case finalRound:
        return Icons.calendar_today;
      case offer:
        return Icons.work;
      case accepted:
        return Icons.check_circle;
      case rejected:
        return Icons.cancel;
      case withdrawn:
        return Icons.undo;
      default:
        return Icons.help;
    }
  }
}

/// Animation Durations
class AppDurations {
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 250);
}

/// Legacy Constants (for backward compatibility)
const Color kPrimaryColor = AppColors.primary;
const Color kSecondaryColor = AppColors.secondary;
const Color kBackgroundColor = AppColors.background;

const TextStyle kHeadingStyle = AppTextStyles.heading3;
const TextStyle kSubheadingStyle = AppTextStyles.heading4;
const TextStyle kBodyStyle = AppTextStyles.bodyMedium;

const TextStyle kHeadingStyleDark = AppTextStyles.heading3Dark;
const TextStyle kSubheadingStyleDark = AppTextStyles.heading4Dark;
const TextStyle kBodyStyleDark = AppTextStyles.bodyMediumDark;