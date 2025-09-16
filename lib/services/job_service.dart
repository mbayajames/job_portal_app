import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Post a job (employer UID is automatically saved)
  Future<void> postJob(JobModel job, String employerUid) async {
    await _firestore.collection('jobs').add({
      'title': job.title,
      'description': job.description,
      'salary': job.salary,
      'employerId': employerUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Fetch all jobs
  Stream<List<JobModel>> fetchJobs() {
    return _firestore.collection('jobs').orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
    );
  }

  // Fetch jobs posted by a specific employer
  Stream<List<JobModel>> fetchEmployerJobs(String employerUid) {
    return _firestore
        .collection('jobs')
        .where('employerId', isEqualTo: employerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList());
  }
}
