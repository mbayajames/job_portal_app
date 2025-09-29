import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class ApplicationSubmissionHelper {
  static final Logger _logger = Logger('ApplicationSubmissionHelper');
  
  // Test if Firestore permissions are working
  static Future<bool> testFirestorePermissions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user for permission test');
        return false;
      }

      // Try to read from applications collection
      await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      _logger.info('Permission test successful: Can read applications');
      return true;
    } catch (e) {
      _logger.severe('Permission test failed: $e');
      return false;
    }
  }
  
  // Submit application with enhanced error handling
  static Future<Map<String, dynamic>> submitApplicationSafely({
    required String jobId,
    required String jobTitle,
    required String companyName,
    required String fullName,
    required String email,
    required String phone,
    required String coverLetter,
    required String resumeUrl,
    required String experience,
    required String education,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
          'code': 'auth_required'
        };
      }

      // First test permissions
      final hasPermissions = await testFirestorePermissions();
      if (!hasPermissions) {
        return {
          'success': false,
          'error': 'Insufficient permissions. Please contact support.',
          'code': 'permission_denied'
        };
      }

      // Prepare application data
      final applicationData = {
        'userId': user.uid,
        'userEmail': user.email,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'companyName': companyName,
        'status': 'pending',
        'appliedDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'coverLetter': coverLetter.trim(),
        'resumeUrl': resumeUrl,
        'experience': experience,
        'education': education,
        'metadata': {
          'submittedFrom': 'mobile_app',
          'version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
        }
      };

      // Check if user has already applied for this job
      final existingApplication = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .where('jobId', isEqualTo: jobId)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'You have already applied for this position',
          'code': 'already_applied'
        };
      }

      // Submit the application
      final docRef = await FirebaseFirestore.instance
          .collection('applications')
          .add(applicationData);

      _logger.info('Application submitted successfully with ID: ${docRef.id}');

      return {
        'success': true,
        'applicationId': docRef.id,
        'message': 'Application submitted successfully!'
      };

    } catch (e) {
      _logger.severe('Error submitting application: $e');
      
      String errorMessage = 'Failed to submit application';
      String errorCode = 'unknown_error';
      
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your account permissions.';
        errorCode = 'permission_denied';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
        errorCode = 'network_error';
      } else if (e.toString().contains('unavailable')) {
        errorMessage = 'Service temporarily unavailable. Please try again later.';
        errorCode = 'service_unavailable';
      } else if (e.toString().contains('invalid-argument')) {
        errorMessage = 'Invalid data provided. Please check your inputs.';
        errorCode = 'invalid_data';
      }

      return {
        'success': false,
        'error': errorMessage,
        'code': errorCode,
        'details': e.toString()
      };
    }
  }

  // Show styled error dialog
  static void showErrorDialog(BuildContext context, String title, String message, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: Colors.red[600])),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('RETRY'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  static void showSuccessDialog(BuildContext context, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text('Success', style: TextStyle(color: Colors.green[600])),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onOk != null) onOk();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Enhanced SnackBar helper
class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green[600]!;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red[600]!;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange[600]!;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue[600]!;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}

enum SnackBarType { success, error, warning, info }