import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String? resumeUrl;
  final String? coverLetterUrl;
  final String details;
  final Map<String, String> questionAnswers;
  final String status;
  final Timestamp createdAt;

  Application({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.resumeUrl,
    this.coverLetterUrl,
    required this.details,
    required this.questionAnswers,
    required this.status,
    required this.createdAt,
  });

  factory Application.fromMap(Map<String, dynamic> map, String id) {
    return Application(
      id: id,
      jobId: map['jobId'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      resumeUrl: map['resumeUrl'],
      coverLetterUrl: map['coverLetterUrl'],
      details: map['details'] ?? '',
      questionAnswers: Map<String, String>.from(map['questionAnswers'] ?? {}),
      status: map['status'] ?? 'Pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'resumeUrl': resumeUrl,
      'coverLetterUrl': coverLetterUrl,
      'details': details,
      'questionAnswers': questionAnswers,
      'status': status,
      'createdAt': createdAt,
    };
  }
}