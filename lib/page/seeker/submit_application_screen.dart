// Make sure you have these imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SubmitApplication');

void submitApplication() async {
  try {
    // Check if user is logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logger.warning("User not logged in");
      return;
    }

    // Write to Firestore
    await FirebaseFirestore.instance.collection('applications').add({
      'userId': user.uid,
      'userEmail': user.email,
      'jobId': 'your-job-id-here',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'fullName': 'Applicant Name',
      'resumeUrl': 'path/to/resume',
    });

    _logger.info("Application submitted successfully!");
  } catch (e) {
    _logger.severe("Error submitting application: $e");
  }
}