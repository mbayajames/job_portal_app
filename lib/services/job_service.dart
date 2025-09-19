import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<JobModel>> getJobsStream({int? limit}) {
    Query<Map<String, dynamic>> query = _firestore.collection('jobs').orderBy('createdAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<JobModel>> getSavedJobsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_jobs')
        .snapshots()
        .asyncMap((snapshot) async {
      final jobs = <JobModel>[];
      for (var doc in snapshot.docs) {
        final jobDoc = await _firestore.collection('jobs').doc(doc.id).get();
        if (jobDoc.exists) {
          final job = JobModel.fromMap(jobDoc.data()!, jobDoc.id);
          jobs.add(job.copyWith(isSaved: true));
        }
      }
      return jobs;
    });
  }

  Future<void> toggleSaveJob(String userId, String jobId) async {
    final ref = _firestore.collection('users').doc(userId).collection('saved_jobs').doc(jobId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({'savedAt': FieldValue.serverTimestamp()});
    }
  }

  Future<List<Map<String, dynamic>>> getJobQuestions(String jobId) async {
    final snapshot = await _firestore.collection('jobs/$jobId/questions').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}