import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final CollectionReference jobsRef =
      FirebaseFirestore.instance.collection('jobs');

  /// Create a new job
  Future<void> createJob(JobModel job) async {
    await jobsRef.add(job.toMap());
  }

  /// Update an existing job
  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    await jobsRef.doc(jobId).update(data);
  }

  /// Delete a job
  Future<void> deleteJob(String jobId) async {
    await jobsRef.doc(jobId).delete();
  }

  /// Get all jobs (for seekers)
  Stream<List<JobModel>> getAllJobs() {
    return jobsRef.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return JobModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      },
    );
  }

  /// Get jobs posted by a specific employer
  Stream<List<JobModel>> getJobsByEmployer(String employerId) {
    return jobsRef
        .where('postedBy', isEqualTo: employerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
