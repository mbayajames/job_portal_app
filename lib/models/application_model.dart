import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String? id;
  final String jobId;
  final String userId;
  final DateTime appliedAt;

  ApplicationModel({
    this.id,
    required this.jobId,
    required this.userId,
    required this.appliedAt,
  });

  /// Convert ApplicationModel -> Map
  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'userId': userId,
      'appliedAt': appliedAt,
    };
  }

  /// Convert Map -> ApplicationModel
  factory ApplicationModel.fromMap(String id, Map<String, dynamic> map) {
    return ApplicationModel(
      id: id,
      jobId: map['jobId'] ?? '',
      userId: map['userId'] ?? '',
      appliedAt: (map['appliedAt'] as Timestamp).toDate(),
    );
  }
}
