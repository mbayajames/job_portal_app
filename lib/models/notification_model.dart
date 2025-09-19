import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool read;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.read = false,
    required this.timestamp,
  });

  // Create NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert NotificationModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'read': read,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Copy with updated fields (useful for marking read)
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    bool? read,
    DateTime? timestamp,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}