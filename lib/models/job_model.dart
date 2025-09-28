// lib/models/job_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String description;
  final String company;
  final String employerId;
  final String location;
  final String salaryRange;
  final String employmentType;
  final String experienceLevel;
  final List<String> requirements;
  final List<String> responsibilities;
  final List<String> benefits;
  final DateTime createdAt;
  final DateTime applicationDeadline;
  final int applicationCount;
  final bool isRemote;
  final String category;
  final String industry;
  final String contactEmail;
  final String applicationInstructions;
  final String status;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    required this.employerId,
    required this.location,
    required this.salaryRange,
    required this.employmentType,
    required this.experienceLevel,
    required this.requirements,
    required this.responsibilities,
    required this.benefits,
    required this.createdAt,
    required this.applicationDeadline,
    required this.applicationCount,
    required this.isRemote,
    required this.category,
    required this.industry,
    required this.contactEmail,
    required this.applicationInstructions,
    required this.status,
  });

  /// Create from Firestore Map
  factory JobModel.fromMap(Map<String, dynamic>? map, String id) {
    final data = map ?? {};
    return JobModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      company: data['company'] ?? '',
      employerId: data['employerId'] ?? '',
      location: data['location'] ?? '',
      salaryRange: data['salaryRange']?.toString() ?? '',
      employmentType: data['employmentType'] ?? 'Full-time',
      experienceLevel: data['experienceLevel'] ?? 'Mid',
      requirements: List<String>.from(data['requirements'] ?? []),
      responsibilities: List<String>.from(data['responsibilities'] ?? []),
      benefits: List<String>.from(data['benefits'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applicationDeadline: (data['applicationDeadline'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      applicationCount: data['applicationCount'] ?? 0,
      isRemote: data['isRemote'] ?? false,
      category: data['category'] ?? '',
      industry: data['industry'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      applicationInstructions: data['applicationInstructions'] ?? '',
      status: data['status'] ?? 'open',
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory JobModel.fromFirestore(DocumentSnapshot doc) =>
      JobModel.fromMap(doc.data() as Map<String, dynamic>?, doc.id);

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'company': company,
        'employerId': employerId,
        'location': location,
        'salaryRange': salaryRange,
        'employmentType': employmentType,
        'experienceLevel': experienceLevel,
        'requirements': requirements,
        'responsibilities': responsibilities,
        'benefits': benefits,
        'createdAt': Timestamp.fromDate(createdAt),
        'applicationDeadline': Timestamp.fromDate(applicationDeadline),
        'applicationCount': applicationCount,
        'isRemote': isRemote,
        'category': category,
        'industry': industry,
        'contactEmail': contactEmail,
        'applicationInstructions': applicationInstructions,
        'status': status,
      };

  /// Copy with
  JobModel copyWith({
    String? id,
    String? title,
    String? description,
    String? company,
    String? employerId,
    String? location,
    String? salaryRange,
    String? employmentType,
    String? experienceLevel,
    List<String>? requirements,
    List<String>? responsibilities,
    List<String>? benefits,
    DateTime? createdAt,
    DateTime? applicationDeadline,
    int? applicationCount,
    bool? isRemote,
    String? category,
    String? industry,
    String? contactEmail,
    String? applicationInstructions,
    String? status,
  }) =>
      JobModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        company: company ?? this.company,
        employerId: employerId ?? this.employerId,
        location: location ?? this.location,
        salaryRange: salaryRange ?? this.salaryRange,
        employmentType: employmentType ?? this.employmentType,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        requirements: requirements ?? this.requirements,
        responsibilities: responsibilities ?? this.responsibilities,
        benefits: benefits ?? this.benefits,
        createdAt: createdAt ?? this.createdAt,
        applicationDeadline: applicationDeadline ?? this.applicationDeadline,
        applicationCount: applicationCount ?? this.applicationCount,
        isRemote: isRemote ?? this.isRemote,
        category: category ?? this.category,
        industry: industry ?? this.industry,
        contactEmail: contactEmail ?? this.contactEmail,
        applicationInstructions:
            applicationInstructions ?? this.applicationInstructions,
        status: status ?? this.status,
      );

  /// Helper: Check if job application deadline is expired
  bool get isExpired => applicationDeadline.isBefore(DateTime.now());

  /// Helper: Check if user can still apply
  bool get canApply => !isExpired;
}
