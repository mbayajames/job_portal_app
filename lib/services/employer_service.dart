import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

class EmployerService {
  final Logger _logger = Logger('EmployerService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Create or update employer profile
  Future<void> saveEmployerProfile(String employerId, Map<String, dynamic> profileData) async {
    await _firestore.collection('employers').doc(employerId).set({
      ...profileData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Post a new job
  Future<String> postJob(Map<String, dynamic> jobData) async {
    final docRef = _firestore.collection('jobs').doc();
    await docRef.set({
      ...jobData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active', // active/closed
    });
    return docRef.id;
  }

  /// Update a job
  Future<void> updateJob(String jobId, Map<String, dynamic> jobData) async {
    await _firestore.collection('jobs').doc(jobId).update({
      ...jobData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a job
  Future<void> deleteJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).delete();
  }

  /// Close a job
  Future<void> closeJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all jobs by employer
  Stream<QuerySnapshot> getJobsByEmployer(String employerId) {
    return _firestore
        .collection('jobs')
        .where('employerId', isEqualTo: employerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get jobs for employer (alias for getJobsByEmployer)
  Stream<QuerySnapshot> getJobsForEmployer(String employerId) {
    return getJobsByEmployer(employerId);
  }

  /// Get applications for a specific job
  Stream<QuerySnapshot> getApplicationsForJob(String jobId) {
    return _firestore.collection('applications').where('jobId', isEqualTo: jobId).snapshots();
  }

  /// Get notifications for employer
  Stream<QuerySnapshot> getNotificationsForEmployer(String employerId) {
    return _firestore.collection('notifications').where('employerId', isEqualTo: employerId).orderBy('createdAt', descending: true).snapshots();
  }

  /// Get job counts by status for employer
  Future<Map<String, int>> getJobCountsByStatus(String employerId) async {
    final snapshot = await _firestore.collection('jobs').where('employerId', isEqualTo: employerId).get();
    final counts = <String, int>{};
    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] ?? 'active';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    counts['total'] = snapshot.docs.length;
    return counts;
  }

  /// Get total applications for employer
  Future<int> getTotalApplicationsForEmployer(String employerId) async {
    final jobsSnapshot = await _firestore.collection('jobs').where('employerId', isEqualTo: employerId).get();
    int total = 0;
    for (var jobDoc in jobsSnapshot.docs) {
      final appsSnapshot = await _firestore.collection('applications').where('jobId', isEqualTo: jobDoc.id).get();
      total += appsSnapshot.docs.length;
    }
    return total;
  }

  /// Get recent applicants for employer
  Stream<QuerySnapshot> getRecentApplicantsForEmployer(String employerId, {int limit = 5}) {
    return _firestore.collection('applications').where('employerId', isEqualTo: employerId).orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  /// Upload logo to Firebase Storage and return download URL
  Future<String?> uploadLogo(dynamic file, String employerId) async {
    try {
      String fileName;
      UploadTask uploadTask;

      if (file is File) {
        fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final ref = _storage.ref().child('employers/$employerId/$fileName');
        uploadTask = ref.putFile(file);
      } else if (file is XFile) {
        fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = _storage.ref().child('employers/$employerId/$fileName');
        final bytes = await file.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        throw UnsupportedError('Unsupported file type: ${file.runtimeType}');
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _logger.severe("Error uploading logo: $e");
      return null;
    }
  }
}
