import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String? id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String postedBy;
  final DateTime createdAt;
  final String type; // NEW: job type e.g. Full-Time

  JobModel({
    this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.postedBy,
    required this.createdAt,
    this.type = 'Full-Time', // default
  });

  /// Convert JobModel -> Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'description': description,
      'postedBy': postedBy,
      'createdAt': createdAt,
      'type': type,
    };
  }

  /// Convert Firestore -> JobModel
  factory JobModel.fromMap(String id, Map<String, dynamic> map) {
    // createdAt in Firestore can be Timestamp, String, or DateTime
    final dynamic createdAtValue = map['createdAt'];
    DateTime createdAt;
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else {
      createdAt = DateTime.now();
    }

    return JobModel(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      postedBy: map['postedBy'] ?? '',
      createdAt: createdAt,
      type: map['type'] ?? 'Full-Time',
    );
  }
}
