import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String? id;
  final String userId; // Firestore document ID / UID
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final DateTime? dateOfBirth;
  final String? location;

  // Professional / Career Info
  final String? currentJobTitle;
  final String? currentCompany;
  final List<Map<String, dynamic>> experience;
  final List<Map<String, dynamic>> education;
  final List<String> skills;
  final List<String> languages;
  final List<Map<String, String>> certifications;

  // Resume / Documents
  final String? resumeUrl;
  final String? coverLetterUrl;
  final String? portfolioUrl;

  // Job Preferences
  final List<String> desiredJobTitles;
  final List<String> desiredLocations;
  final String? preferredJobType;
  final double? expectedSalary;

  // Jobs & Applications
  final List<String> appliedJobs;
  final List<String> savedJobs;

  // NEW: Track how many free applications the user has used
  final int applicationsUsed;

  // Employer fields (optional)
  final String? companyName;
  final String? companyWebsite;
  final String? companyLogoUrl;

  // Account & Settings
  final String role; // 'employee' or 'employer'
  final bool notificationsEnabled;
  final bool twoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profilePictureUrl,
    this.dateOfBirth,
    this.location,
    this.currentJobTitle,
    this.currentCompany,
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    this.languages = const [],
    this.certifications = const [],
    this.resumeUrl,
    this.coverLetterUrl,
    this.portfolioUrl,
    this.desiredJobTitles = const [],
    this.desiredLocations = const [],
    this.preferredJobType,
    this.expectedSalary,
    this.appliedJobs = const [],
    this.savedJobs = const [],
    this.applicationsUsed = 0, // default 0
    this.companyName,
    this.companyWebsite,
    this.companyLogoUrl,
    required this.role,
    this.notificationsEnabled = true,
    this.twoFactorEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map, {String? id}) {
    List<Map<String, String>> mapToStringMapList(dynamic list) {
      if (list is List) {
        return list.map((e) {
          if (e is Map) {
            return e.map((key, value) => MapEntry(key.toString(), value.toString()));
          }
          return <String, String>{};
        }).toList();
      }
      return [];
    }

    List<Map<String, dynamic>> mapToDynamicMapList(dynamic list) {
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }

    return ProfileModel(
      id: id ?? map['id'],
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['phone'],
      profilePictureUrl: map['profilePictureUrl'] ?? map['photoUrl'],
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      location: map['location'],
      currentJobTitle: map['currentJobTitle'],
      currentCompany: map['currentCompany'],
      experience: mapToDynamicMapList(map['experience']),
      education: mapToDynamicMapList(map['education']),
      skills: List<String>.from(map['skills'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      certifications: mapToStringMapList(map['certifications']),
      resumeUrl: map['resumeUrl'],
      coverLetterUrl: map['coverLetterUrl'],
      portfolioUrl: map['portfolioUrl'],
      desiredJobTitles: List<String>.from(map['desiredJobTitles'] ?? []),
      desiredLocations: List<String>.from(map['desiredLocations'] ?? []),
      preferredJobType: map['preferredJobType'],
      expectedSalary: map['expectedSalary'] != null
          ? (map['expectedSalary'] as num).toDouble()
          : null,
      appliedJobs: List<String>.from(map['appliedJobs'] ?? []),
      savedJobs: List<String>.from(map['savedJobs'] ?? []),
      applicationsUsed: map['applicationsUsed'] ?? 0, // NEW
      companyName: map['companyName'],
      companyWebsite: map['companyWebsite'],
      companyLogoUrl: map['companyLogoUrl'],
      role: map['role'] ?? 'employee',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'dateOfBirth': dateOfBirth,
      'location': location,
      'currentJobTitle': currentJobTitle,
      'currentCompany': currentCompany,
      'experience': experience,
      'education': education,
      'skills': skills,
      'languages': languages,
      'certifications': certifications,
      'resumeUrl': resumeUrl,
      'coverLetterUrl': coverLetterUrl,
      'portfolioUrl': portfolioUrl,
      'desiredJobTitles': desiredJobTitles,
      'desiredLocations': desiredLocations,
      'preferredJobType': preferredJobType,
      'expectedSalary': expectedSalary,
      'appliedJobs': appliedJobs,
      'savedJobs': savedJobs,
      'applicationsUsed': applicationsUsed, // NEW
      'companyName': companyName,
      'companyWebsite': companyWebsite,
      'companyLogoUrl': companyLogoUrl,
      'role': role,
      'notificationsEnabled': notificationsEnabled,
      'twoFactorEnabled': twoFactorEnabled,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profilePictureUrl,
    DateTime? dateOfBirth,
    String? location,
    String? currentJobTitle,
    String? currentCompany,
    List<Map<String, dynamic>>? experience,
    List<Map<String, dynamic>>? education,
    List<String>? skills,
    List<String>? languages,
    List<Map<String, String>>? certifications,
    String? resumeUrl,
    String? coverLetterUrl,
    String? portfolioUrl,
    List<String>? desiredJobTitles,
    List<String>? desiredLocations,
    String? preferredJobType,
    double? expectedSalary,
    List<String>? appliedJobs,
    List<String>? savedJobs,
    int? applicationsUsed, // NEW
    String? companyName,
    String? companyWebsite,
    String? companyLogoUrl,
    String? role,
    bool? notificationsEnabled,
    bool? twoFactorEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      currentJobTitle: currentJobTitle ?? this.currentJobTitle,
      currentCompany: currentCompany ?? this.currentCompany,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      certifications: certifications ?? this.certifications,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      coverLetterUrl: coverLetterUrl ?? this.coverLetterUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      desiredJobTitles: desiredJobTitles ?? this.desiredJobTitles,
      desiredLocations: desiredLocations ?? this.desiredLocations,
      preferredJobType: preferredJobType ?? this.preferredJobType,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      appliedJobs: appliedJobs ?? this.appliedJobs,
      savedJobs: savedJobs ?? this.savedJobs,
      applicationsUsed: applicationsUsed ?? this.applicationsUsed, // NEW
      companyName: companyName ?? this.companyName,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      role: role ?? this.role,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
