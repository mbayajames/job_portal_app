import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String employerId;
  final String title;
  final String companyName;
  final String location;
  final String salaryRange;
  final String description;
  final String jobType;
  final String? category;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final bool isSaved;

  JobModel({
    required this.id,
    required this.employerId,
    required this.title,
    required this.companyName,
    required this.location,
    required this.salaryRange,
    required this.description,
    required this.jobType,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isSaved = false,
  });

  factory JobModel.fromMap(Map<String, dynamic> data, String id) {
    return JobModel(
      id: id,
      employerId: data['employerId'] ?? '',
      title: data['title'] ?? '',
      companyName: data['companyName'] ?? '',
      location: data['location'] ?? '',
      salaryRange: data['salaryRange'] ?? '',
      description: data['description'] ?? '',
      jobType: data['jobType'] ?? '',
      category: data['category'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      isSaved: data['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employerId': employerId,
      'title': title,
      'companyName': companyName,
      'location': location,
      'salaryRange': salaryRange,
      'description': description,
      'jobType': jobType,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  JobModel copyWith({bool? isSaved}) {
    return JobModel(
      id: id,
      employerId: employerId,
      title: title,
      companyName: companyName,
      location: location,
      salaryRange: salaryRange,
      description: description,
      jobType: jobType,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}