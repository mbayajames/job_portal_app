class UserModel {
  final String id;
  final String email;
  final String fullName; // keeps fullName from original
  final String role; // added from User
  final String? phone;
  final String? address; // added from User
  final String? profileImage;
  final String? resumeUrl;
  final List<Education> education;
  final List<WorkExperience> experience;
  final List<String> skills;
  final CareerPreferences preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.address,
    this.profileImage,
    this.resumeUrl,
    required this.education,
    required this.experience,
    required this.skills,
    required this.preferences,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      role: json['role'] ?? 'user',
      phone: json['phone'],
      address: json['address'],
      profileImage: json['profileImage'],
      resumeUrl: json['resumeUrl'],
      education: (json['education'] as List? ?? [])
          .map((e) => Education.fromJson(e))
          .toList(),
      experience: (json['experience'] as List? ?? [])
          .map((e) => WorkExperience.fromJson(e))
          .toList(),
      skills: List<String>.from(json['skills'] ?? []),
      preferences: CareerPreferences.fromJson(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'phone': phone,
      'address': address,
      'profileImage': profileImage,
      'resumeUrl': resumeUrl,
      'education': education.map((e) => e.toJson()).toList(),
      'experience': experience.map((e) => e.toJson()).toList(),
      'skills': skills,
      'preferences': preferences.toJson(),
    };
  }

  UserModel copyWith({
    String? email,
    String? fullName,
    String? role,
    String? phone,
    String? address,
    String? profileImage,
    String? resumeUrl,
    List<Education>? education,
    List<WorkExperience>? experience,
    List<String>? skills,
    CareerPreferences? preferences,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      preferences: preferences ?? this.preferences,
    );
  }
}

class Education {
  final String institution;
  final String degree;
  final String field;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;

  Education({
    required this.institution,
    required this.degree,
    required this.field,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution'],
      degree: json['degree'],
      field: json['field'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'field': field,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }
}

class WorkExperience {
  final String company;
  final String position;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;

  WorkExperience({
    required this.company,
    required this.position,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      company: json['company'],
      position: json['position'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }
}

class CareerPreferences {
  final String jobType; // full-time, part-time, contract, etc.
  final String preferredLocation;
  final double minSalary;
  final List<String> preferredIndustries;
  final String experienceLevel;

  CareerPreferences({
    required this.jobType,
    required this.preferredLocation,
    required this.minSalary,
    required this.preferredIndustries,
    required this.experienceLevel,
  });

  factory CareerPreferences.fromJson(Map<String, dynamic> json) {
    return CareerPreferences(
      jobType: json['jobType'] ?? 'Full-time',
      preferredLocation: json['preferredLocation'] ?? '',
      minSalary: (json['minSalary'] ?? 0).toDouble(),
      preferredIndustries: List<String>.from(json['preferredIndustries'] ?? []),
      experienceLevel: json['experienceLevel'] ?? 'Mid-level',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobType': jobType,
      'preferredLocation': preferredLocation,
      'minSalary': minSalary,
      'preferredIndustries': preferredIndustries,
      'experienceLevel': experienceLevel,
    };
  }

  CareerPreferences copyWith({
    String? jobType,
    String? preferredLocation,
    double? minSalary,
    List<String>? preferredIndustries,
    String? experienceLevel,
  }) {
    return CareerPreferences(
      jobType: jobType ?? this.jobType,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      minSalary: minSalary ?? this.minSalary,
      preferredIndustries: preferredIndustries ?? this.preferredIndustries,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }
}
