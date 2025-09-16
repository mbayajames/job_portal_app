import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String seekerId;
  final String status;

  ApplicationModel({required this.id, required this.jobId, required this.seekerId, required this.status});

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      seekerId: data['seekerId'] ?? '',
      status: data['status'] ?? '',
    );
  }
}
