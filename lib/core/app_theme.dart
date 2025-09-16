import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kBackgroundColor,
    colorScheme: ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
    ),
    textTheme: const TextTheme(
      displayLarge: kHeadingStyle,
      headlineSmall: kSubheadingStyle,
      bodyMedium: kBodyStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
    ),
    textTheme: const TextTheme(
      displayLarge: kHeadingStyle,
      headlineSmall: kSubheadingStyle,
      bodyMedium: kBodyStyle,
    ),
  );
}
