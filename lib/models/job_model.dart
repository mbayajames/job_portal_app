import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String description;
  final double salary;
  final String employerId;
  final Timestamp? createdAt;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.salary,
    required this.employerId,
    this.createdAt,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      salary: (data['salary'] as num?)?.toDouble() ?? 0.0,
      employerId: data['employerId'] ?? '',
      createdAt: data['createdAt'] != null ? data['createdAt'] as Timestamp : Timestamp.now(),
    );
  }
}