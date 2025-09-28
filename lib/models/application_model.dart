import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'job_model.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyId;
  final String companyName;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String resumeUrl;
  final String coverLetter;
  final String status; // pending, under_review, accepted, rejected
  final DateTime appliedDate;
  final DateTime? updatedDate;
  final Map<String, dynamic> additionalAnswers;
  final String? notes;
  final String? feedback;
  final String location;
  final String jobType;
  final List<Map<String, dynamic>> statusHistory;
  final String userId;
  final Map<String, dynamic> applicationData;
  final bool isPaid;
  final String? paymentId;
  final String email;
  final String phone;
  final double salary;
  final bool isFavorite;
  final JobModel? job;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyId,
    required this.companyName,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.resumeUrl,
    required this.coverLetter,
    required this.status,
    required this.appliedDate,
    this.updatedDate,
    required this.additionalAnswers,
    this.notes,
    this.feedback,
    required this.location,
    required this.jobType,
    required this.statusHistory,
    required this.userId,
    required this.applicationData,
    required this.isPaid,
    this.paymentId,
    required this.email,
    required this.phone,
    required this.salary,
    this.isFavorite = false,
    this.job,
  });

  /// Firestore + JSON factory
  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      id: map['id'] ?? '',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      applicantId: map['applicantId'] ?? '',
      applicantName: map['applicantName'] ?? '',
      applicantEmail: map['applicantEmail'] ?? '',
      resumeUrl: map['resumeUrl'] ?? '',
      coverLetter: map['coverLetter'] ?? '',
      status: map['status'] ?? 'pending',
      appliedDate: map['appliedDate'] != null
          ? (map['appliedDate'] is Timestamp
              ? (map['appliedDate'] as Timestamp).toDate()
              : DateTime.tryParse(map['appliedDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedDate: map['updatedDate'] != null
          ? (map['updatedDate'] is Timestamp
              ? (map['updatedDate'] as Timestamp).toDate()
              : DateTime.tryParse(map['updatedDate'].toString()))
          : null,
      additionalAnswers: Map<String, dynamic>.from(map['additionalAnswers'] ?? {}),
      notes: map['notes'],
      feedback: map['feedback'],
      location: map['location'] ?? '',
      jobType: map['jobType'] ?? '',
      statusHistory: List<Map<String, dynamic>>.from(map['statusHistory'] ?? []),
      userId: map['userId'] ?? '',
      applicationData: Map<String, dynamic>.from(map['applicationData'] ?? {}),
      isPaid: map['isPaid'] ?? false,
      paymentId: map['paymentId'],
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      salary: (map['salary'] ?? 0).toDouble(),
      isFavorite: map['isFavorite'] ?? false,
      job: map['job'] != null ? JobModel.fromMap(Map<String, dynamic>.from(map['job']), map['jobId'] ?? '') : null,
    );
  }

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      ApplicationModel.fromMap(json);

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyId': companyId,
      'companyName': companyName,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'resumeUrl': resumeUrl,
      'coverLetter': coverLetter,
      'status': status,
      'appliedDate': Timestamp.fromDate(appliedDate),
      if (updatedDate != null) 'updatedDate': Timestamp.fromDate(updatedDate!),
      'additionalAnswers': additionalAnswers,
      'notes': notes,
      'feedback': feedback,
      'location': location,
      'jobType': jobType,
      'statusHistory': statusHistory,
      'userId': userId,
      'applicationData': applicationData,
      'isPaid': isPaid,
      'paymentId': paymentId,
      'email': email,
      'phone': phone,
      'salary': salary,
      'isFavorite': isFavorite,
      if (job != null) 'job': job!.toMap(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? companyId,
    String? companyName,
    String? applicantId,
    String? applicantName,
    String? applicantEmail,
    String? resumeUrl,
    String? coverLetter,
    String? status,
    DateTime? appliedDate,
    DateTime? updatedDate,
    Map<String, dynamic>? additionalAnswers,
    String? notes,
    String? feedback,
    String? location,
    String? jobType,
    List<Map<String, dynamic>>? statusHistory,
    String? userId,
    Map<String, dynamic>? applicationData,
    bool? isPaid,
    String? paymentId,
    String? email,
    String? phone,
    double? salary,
    bool? isFavorite,
    JobModel? job,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      updatedDate: updatedDate ?? this.updatedDate,
      additionalAnswers: additionalAnswers ?? this.additionalAnswers,
      notes: notes ?? this.notes,
      feedback: feedback ?? this.feedback,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      statusHistory: statusHistory ?? this.statusHistory,
      userId: userId ?? this.userId,
      applicationData: applicationData ?? this.applicationData,
      isPaid: isPaid ?? this.isPaid,
      paymentId: paymentId ?? this.paymentId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      salary: salary ?? this.salary,
      isFavorite: isFavorite ?? this.isFavorite,
      job: job ?? this.job,
    );
  }

  /// Helpers
  bool isStatus(String check) => status.toLowerCase() == check.toLowerCase();

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under Review';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Map<String, dynamic> toSimpleMap() {
    return {
      'id': id,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'status': status,
      'appliedDate': appliedDate,
      'applicantName': applicantName,
    };
  }
}

/// ✅ Typedef for easier usage
typedef Application = ApplicationModel;
