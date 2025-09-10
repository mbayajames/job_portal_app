import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

class ApplicationService {
  final CollectionReference applications =
      FirebaseFirestore.instance.collection('applications');

  /// Apply to a job using named parameters
  Future<void> applyToJob({required String jobId, required String userId}) async {
    final app = ApplicationModel(
      jobId: jobId,
      userId: userId,
      appliedAt: DateTime.now(),
    );

    await applications.add(app.toMap());
  }

  /// Stream of applications for current user
  Stream<List<ApplicationModel>> getUserApplications(String userId) {
    return applications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ApplicationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
}
