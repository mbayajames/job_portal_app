// lib/services/job_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'jobs';

  // ------------------------------
  // JOB STREAMS
  // ------------------------------
  Stream<List<JobModel>> getJobsStream({int? limit}) {
    Query query = _firestore.collection(collectionName);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<JobModel>> getEmployerJobsStream(String employerId) {
    return _firestore
        .collection(collectionName)
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<JobModel?> getJobById(String jobId) async {
    final doc = await _firestore.collection(collectionName).doc(jobId).get();
    if (doc.exists) {
      return JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // ------------------------------
  // CREATE JOB
  // ------------------------------
  /// Post a job using JobModel and store its Firestore ID in the document
  Future<void> postJob(JobModel job) async {
    final docRef = await _firestore.collection(collectionName).add({
      ...job.toMap(),
      'employerId': job.employerId, // ✅ ensure employerId is saved
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Save the document ID inside the job document
    await docRef.update({'id': docRef.id});
  }

  /// Post a job from a raw Map (useful for PostJobScreen)
  Future<void> postJobFromMap(Map<String, dynamic> jobData) async {
    final docRef = await _firestore.collection(collectionName).add({
      ...jobData,
      'employerId': jobData['employerId'], // ✅ required for employer filtering
      'createdAt': FieldValue.serverTimestamp(),
    });

    await docRef.update({'id': docRef.id});
  }

  // ------------------------------
  // UPDATE & DELETE JOB
  // ------------------------------
  Future<void> updateJob(String jobId, Map<String, dynamic> updates) async {
    await _firestore.collection(collectionName).doc(jobId).update(updates);
  }

  Future<void> deleteJob(String jobId) async {
    await _firestore.collection(collectionName).doc(jobId).delete();
  }

  // ------------------------------
  // RECOMMENDATION & TRENDING
  // ------------------------------
  Stream<List<JobModel>> getRecommendedJobs(List<String> skills) {
    if (skills.isEmpty) return Stream.value([]);
    return _firestore
        .collection(collectionName)
        .where('title', whereIn: skills.take(10).toList())
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<JobModel>> getTrendingJobs() {
    return getJobsStream(limit: 10);
  }

  Stream<List<JobModel>> getJobsByIds(List<String> jobIds) {
    if (jobIds.isEmpty) return Stream.value([]);
    return _firestore
        .collection(collectionName)
        .where(FieldPath.documentId, whereIn: jobIds)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList());
  }

  // ------------------------------
  // SAVED JOBS
  // ------------------------------
  Stream<List<JobModel>> getSavedJobsStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) return [];
      final data = userDoc.data() as Map<String, dynamic>;
      final savedJobIds = List<String>.from(data['savedJobs'] ?? []);
      if (savedJobIds.isEmpty) return [];
      final snapshot = await _firestore
          .collection(collectionName)
          .where(FieldPath.documentId, whereIn: savedJobIds)
          .get();
      return snapshot.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> toggleSaveJob(String userId, String jobId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    final data = userDoc.data() as Map<String, dynamic>;
    final savedJobs = List<String>.from(data['savedJobs'] ?? []);
    if (savedJobs.contains(jobId)) {
      savedJobs.remove(jobId);
    } else {
      savedJobs.add(jobId);
    }
    await userRef.update({'savedJobs': savedJobs});
  }

  Future<void> trackJobView(String userId, String jobId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    final data = userDoc.data() as Map<String, dynamic>;
    final recentlyViewed = List<String>.from(data['recentlyViewedJobs'] ?? []);
    recentlyViewed.remove(jobId);
    recentlyViewed.insert(0, jobId);
    if (recentlyViewed.length > 10) recentlyViewed.removeLast();
    await userRef.update({'recentlyViewedJobs': recentlyViewed});
  }

  Future<List<String>> getSavedJobIdsForUser(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];
    final data = userDoc.data() as Map<String, dynamic>;
    return List<String>.from(data['savedJobs'] ?? []);
  }

  Future<void> saveJobForUser(String userId, String jobId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    final data = userDoc.data() as Map<String, dynamic>;
    final savedJobs = List<String>.from(data['savedJobs'] ?? []);
    if (!savedJobs.contains(jobId)) {
      savedJobs.add(jobId);
      await userRef.update({'savedJobs': savedJobs});
    }
  }

  Future<void> removeSavedJobForUser(String userId, String jobId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    final data = userDoc.data() as Map<String, dynamic>;
    final savedJobs = List<String>.from(data['savedJobs'] ?? []);
    savedJobs.remove(jobId);
    await userRef.update({'savedJobs': savedJobs});
  }

  // ------------------------------
  // APPLICATIONS
  // ------------------------------
  Future<void> submitApplication(ApplicationModel application) async {
    await _firestore.collection('applications').doc(application.id).set({
      ...application.toMap(),
      'jobId': application.jobId, // ✅ make sure job link is stored
      'applicantId': application.applicantId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
