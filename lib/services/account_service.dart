import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('AccountService');

  /// Fetch user data by user ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) return doc.data();
      return null;
    } catch (e) {
      _logger.severe('Error fetching user: $e');
      return null;
    }
  }

  /// Update user profile data
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(userId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch applications for a seeker or for an employer
  Future<List<Map<String, dynamic>>> getApplications({
    String? userId,
    String? employerId,
  }) async {
    try {
      Query query = _firestore.collection('applications');

      if (userId != null && userId.isNotEmpty) {
        query = query.where('userId', isEqualTo: userId);
      } else if (employerId != null && employerId.isNotEmpty) {
        query = query.where('employerId', isEqualTo: employerId);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        final data = (doc.data() ?? <String, dynamic>{}) as Map<String, dynamic>;
        return <String, dynamic>{'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      _logger.severe('Error fetching applications: $e');
      return [];
    }
  }

  /// Submit a job application with validation
  Future<bool> submitApplication({
    required String userId,
    required String jobId,
    Map<String, dynamic>? applicationData,
  }) async {
    if (jobId.isEmpty || userId.isEmpty) {
      _logger.warning('Error: jobId and userId are required to submit application.');
      return false;
    }

    try {
      final docRef = _firestore.collection('applications').doc();

      await docRef.set({
        'id': docRef.id,
        'userId': userId,
        'jobId': jobId,
        'status': 'submitted',
        'applicationData': applicationData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Optional: track applied jobs in user's document
      await _firestore.collection('users').doc(userId).update({
        'appliedJobs': FieldValue.arrayUnion([jobId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _logger.severe('Error submitting application: $e');
      return false;
    }
  }

  /// Withdraw a submitted application
  Future<bool> withdrawApplication(String applicationId, String userId) async {
    try {
      final docRef = _firestore.collection('applications').doc(applicationId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final jobId = doc.data()!['jobId'];

      await docRef.update({'status': 'withdrawn', 'updatedAt': FieldValue.serverTimestamp()});

      // Optionally remove from user's appliedJobs
      await _firestore.collection('users').doc(userId).update({
        'appliedJobs': FieldValue.arrayRemove([jobId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _logger.severe('Error withdrawing application: $e');
      return false;
    }
  }

  /// Get saved jobs for a user
  Future<List<String>> getSavedJobs(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        final savedJobs = data?['savedJobs'] as List<dynamic>? ?? [];
        return savedJobs.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      _logger.severe('Error fetching saved jobs: $e');
      return [];
    }
  }

  /// Add a job to saved jobs
  Future<void> addSavedJob(String userId, String jobId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'savedJobs': FieldValue.arrayUnion([jobId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.severe('Error adding saved job: $e');
      rethrow;
    }
  }

  /// Remove a job from saved jobs
  Future<void> removeSavedJob(String userId, String jobId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'savedJobs': FieldValue.arrayRemove([jobId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.severe('Error removing saved job: $e');
      rethrow;
    }
  }

  /// Update application status
  Future<bool> updateApplicationStatus({required String applicationId, required String status}) async {
    try {
      await _firestore.collection('applications').doc(applicationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _logger.severe('Error updating application status: $e');
      return false;
    }
  }
}
