class SavedJob {
  final String id;
  final String jobId;
  final String userId;
  final DateTime savedAt;
  final Job jobDetails;
  final String? notes;

  SavedJob({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.savedAt,
    required this.jobDetails,
    this.notes,
  });

  factory SavedJob.fromJson(Map<String, dynamic> json) {
    return SavedJob(
      id: json['id'],
      jobId: json['jobId'],
      userId: json['userId'],
      savedAt: DateTime.parse(json['savedAt']),
      jobDetails: Job.fromJson(json['jobDetails']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'userId': userId,
      'savedAt': savedAt.toIso8601String(),
      'jobDetails': jobDetails.toJson(),
      'notes': notes,
    };
  }
}

// ✅ Keep your existing Job class but add helper methods
class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String type;
  final double salary;
  final String description;
  final List<String> requirements;
  final List<String> skills;
  final DateTime postedDate;
  final String experienceLevel;
  final String industry;
  final String? companyLogo;
  final bool isRemote;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.salary,
    required this.description,
    required this.requirements,
    required this.skills,
    required this.postedDate,
    required this.experienceLevel,
    required this.industry,
    this.companyLogo,
    this.isRemote = false,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      company: json['company'],
      location: json['location'],
      type: json['type'],
      salary: (json['salary'] ?? 0).toDouble(),
      description: json['description'],
      requirements: List<String>.from(json['requirements'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      postedDate: DateTime.parse(json['postedDate']),
      experienceLevel: json['experienceLevel'],
      industry: json['industry'],
      companyLogo: json['companyLogo'],
      isRemote: json['isRemote'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'type': type,
      'salary': salary,
      'description': description,
      'requirements': requirements,
      'skills': skills,
      'postedDate': postedDate.toIso8601String(),
      'experienceLevel': experienceLevel,
      'industry': industry,
      'companyLogo': companyLogo,
      'isRemote': isRemote,
    };
  }

  /// ✅ Create a new Job instance (Add)
  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    String? type,
    double? salary,
    String? description,
    List<String>? requirements,
    List<String>? skills,
    DateTime? postedDate,
    String? experienceLevel,
    String? industry,
    String? companyLogo,
    bool? isRemote,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      type: type ?? this.type,
      salary: salary ?? this.salary,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      skills: skills ?? this.skills,
      postedDate: postedDate ?? this.postedDate,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      industry: industry ?? this.industry,
      companyLogo: companyLogo ?? this.companyLogo,
      isRemote: isRemote ?? this.isRemote,
    );
  }

  /// ✅ Update Job details
  Job update(Map<String, dynamic> updates) {
    return Job(
      id: updates['id'] ?? id,
      title: updates['title'] ?? title,
      company: updates['company'] ?? company,
      location: updates['location'] ?? location,
      type: updates['type'] ?? type,
      salary: (updates['salary'] ?? salary).toDouble(),
      description: updates['description'] ?? description,
      requirements: List<String>.from(updates['requirements'] ?? requirements),
      skills: List<String>.from(updates['skills'] ?? skills),
      postedDate: updates['postedDate'] != null
          ? DateTime.parse(updates['postedDate'])
          : postedDate,
      experienceLevel: updates['experienceLevel'] ?? experienceLevel,
      industry: updates['industry'] ?? industry,
      companyLogo: updates['companyLogo'] ?? companyLogo,
      isRemote: updates['isRemote'] ?? isRemote,
    );
  }
}
