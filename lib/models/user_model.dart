import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role; // seeker, employer, admin
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  /// Convert UserModel -> Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }

  /// Convert Map -> UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'seeker',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
