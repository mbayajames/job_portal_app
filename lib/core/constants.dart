import 'package:flutter/material.dart';

// Colors
const kPrimaryColor = Color(0xFF1A73E8);
const kSecondaryColor = Color(0xFF000000);
const kBackgroundColor = Color(0xFFFFFFFF);
const kTextColor = Colors.black87; // ✅ added
const kLightColor = Color(0xFFF1F3F4); // ✅ added (light gray for inputs, backgrounds)

// AppColors class for easy access
class AppColors {
  static const primary = kPrimaryColor;
  static const secondary = kSecondaryColor;
  static const background = kBackgroundColor;
  static const text = kTextColor;
  static const light = kLightColor;
}

// Text Styles
const kHeadingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kSecondaryColor,
);

const kSubheadingStyle = TextStyle(
  fontSize: 18,
  color: kSecondaryColor,
);

const kBodyStyle = TextStyle(
  fontSize: 14,
  color: kTextColor,
);

// User Roles
const String kJobSeekerRole = "Job Seeker";
const String kEmployerRole = "Employer";

// App Name
const String appName = "Job Portal App";

// Additional colors for consistency
const primaryBlue = kPrimaryColor;
const primaryWhite = Colors.white;
const primaryBlack = Colors.black;
