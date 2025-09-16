import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Apply for a job
  Future<void> applyForJob(String jobId, String seekerId) async {
    await _firestore.collection('applications').add({
      'jobId': jobId,
      'seekerId': seekerId,
      'status': 'applied',
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }

  // Fetch applications for a job
  Stream<List<ApplicationModel>> fetchJobApplications(String jobId) {
    return _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ApplicationModel.fromFirestore(doc)).toList());
  }

  // Fetch applications by a seeker
  Stream<List<ApplicationModel>> fetchSeekerApplications(String seekerId) {
    return _firestore
        .collection('applications')
        .where('seekerId', isEqualTo: seekerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ApplicationModel.fromFirestore(doc)).toList());
  }
}
