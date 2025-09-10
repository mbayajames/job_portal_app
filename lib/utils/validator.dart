class Validator {
  /// Validate Email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    const emailRegex =
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'; // simple regex for email
    if (!RegExp(emailRegex).hasMatch(value.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  /// Validate Password (min 8 chars)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters long";
    }
    return null;
  }

  /// Validate Confirm Password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }
    if (value != password) {
      return "Passwords do not match";
    }
    return null;
  }

  /// Validate Required Field (like job title, description, etc.)
  static String? validateRequired(String? value, {String fieldName = "Field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }

  /// Validate Number Field (like salary)
  static String? validateNumber(String? value, {String fieldName = "Field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    if (double.tryParse(value.trim()) == null) {
      return "$fieldName must be a number";
    }
    return null;
  }
}
