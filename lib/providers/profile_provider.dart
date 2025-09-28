import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _profileService = ProfileService();

  Map<String, dynamic> _profileData = {};
  bool isLoading = false;

  Map<String, dynamic> get profileData => _profileData;

  String? get fullName => _profileData['fullName'];
  String? get profileImageUrl => _profileData['profilePictureUrl'];
  String? get resumeUrl => _profileData['resumeUrl'];
  String? get location => _profileData['location'];
  String? get email => _profileData['email'];
  String? get phone => _profileData['phone'];
  String? get about => _profileData['about'];
  String? get linkedIn => _profileData['linkedIn'];
  String? get github => _profileData['github'];
  String? get website => _profileData['website'];

  List<String> get skills => List<String>.from(_profileData['skills'] ?? []);
  List<Map<String, dynamic>> get education =>
      List<Map<String, dynamic>>.from(_profileData['education'] ?? []);
  List<Map<String, dynamic>> get experience =>
      List<Map<String, dynamic>>.from(_profileData['experience'] ?? []);
  List<String> get certifications =>
      List<String>.from(_profileData['certifications'] ?? []);
  List<String> get jobPreferences =>
      List<String>.from(_profileData['jobPreferences'] ?? []);

  /// ✅ Saved Jobs
  List<String> get savedJobs => List<String>.from(_profileData['savedJobs'] ?? []);

  /// =================== Applications Tracking ===================
  List<String> get appliedJobs => List<String>.from(_profileData['appliedJobs'] ?? []);
  int get applicationsUsed => appliedJobs.length;
  bool get isPremium => _profileData['isPremium'] ?? false;

  bool get isFreeApplicationsExceeded => !isPremium && applicationsUsed >= 3;

  double get profileCompletion {
    int filled = 0;
    if (fullName != null && fullName!.isNotEmpty) filled++;
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) filled++;
    if (resumeUrl != null && resumeUrl!.isNotEmpty) filled++;
    if (location != null && location!.isNotEmpty) filled++;
    if (skills.isNotEmpty) filled++;
    if (education.isNotEmpty) filled++;
    if (experience.isNotEmpty) filled++;
    if (certifications.isNotEmpty) filled++;
    return filled / 8.0;
  }

  /// ================= PROFILE LOAD =================
  Future<void> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection("seekers").doc(user.uid).get();
      _profileData = doc.data() ?? {};
    } catch (e) {
      _profileData = {};
    }

    isLoading = false;
    notifyListeners();
  }

  /// ================= PROFILE UPDATE =================
  Future<void> updateProfileInfo(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection("seekers").doc(user.uid).set(
            data,
            SetOptions(merge: true),
          );
      _profileData.addAll(data);
    } catch (e) {
      // Handle error if needed
    }

    isLoading = false;
    notifyListeners();
  }

  /// ================== APPLICATIONS ===================
  Future<void> addAppliedJob(String jobId) async {
    final current = appliedJobs;
    if (!current.contains(jobId)) {
      current.add(jobId);
      await updateProfileInfo({'appliedJobs': current});
    }
  }

  Future<void> removeAppliedJob(String jobId) async {
    final current = appliedJobs;
    if (current.contains(jobId)) {
      current.remove(jobId);
      await updateProfileInfo({'appliedJobs': current});
    }
  }

  Future<void> setPremiumStatus(bool premium) async {
    await updateProfileInfo({'isPremium': premium});
  }

  /// ================= SAVED JOBS =================
  Future<void> addSavedJob(String jobId) async {
    final current = savedJobs;
    if (!current.contains(jobId)) {
      current.add(jobId);
      await updateProfileInfo({'savedJobs': current});
    }
  }

  Future<void> removeSavedJob(String jobId) async {
    final current = savedJobs;
    if (current.contains(jobId)) {
      current.remove(jobId);
      await updateProfileInfo({'savedJobs': current});
    }
  }

  Future<void> toggleSavedJob(String jobId) async {
    if (savedJobs.contains(jobId)) {
      await removeSavedJob(jobId);
    } else {
      await addSavedJob(jobId);
    }
  }

  bool isJobSaved(String jobId) => savedJobs.contains(jobId);

  /// ================= CERTIFICATIONS =================
  Future<void> addCertification(String certification) async {
    final current = certifications;
    if (!current.contains(certification)) {
      current.add(certification);
      await updateProfileInfo({'certifications': current});
    }
  }

  Future<void> removeCertification(String certification) async {
    final current = certifications;
    if (current.contains(certification)) {
      current.remove(certification);
      await updateProfileInfo({'certifications': current});
    }
  }

  /// ================= SKILLS =================
  Future<void> addSkill(String skill) async {
    final current = skills;
    if (!current.contains(skill)) {
      current.add(skill);
      await updateProfileInfo({'skills': current});
    }
  }

  Future<void> removeSkill(String skill) async {
    final current = skills;
    if (current.contains(skill)) {
      current.remove(skill);
      await updateProfileInfo({'skills': current});
    }
  }

  /// ================= JOB PREFERENCES =================
  Future<void> addJobPreference(String preference) async {
    final current = jobPreferences;
    if (!current.contains(preference)) {
      current.add(preference);
      await updateProfileInfo({'jobPreferences': current});
    }
  }

  Future<void> removeJobPreference(String preference) async {
    final current = jobPreferences;
    if (current.contains(preference)) {
      current.remove(preference);
      await updateProfileInfo({'jobPreferences': current});
    }
  }

  /// ================= EDUCATION =================
  Future<void> addEducation({required String degree, required String institution, required String year}) async {
    final current = education;
    current.add({'degree': degree, 'institution': institution, 'year': year});
    await updateProfileInfo({'education': current});
  }

  Future<void> removeEducation(int index) async {
    final current = education;
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
      await updateProfileInfo({'education': current});
    }
  }

  /// ================= EXPERIENCE =================
  Future<void> addExperience({required String title, required String company, String? duration, String? responsibilities}) async {
    final current = experience;
    current.add({'title': title, 'company': company, 'duration': duration ?? '', 'responsibilities': responsibilities});
    await updateProfileInfo({'experience': current});
  }

  Future<void> removeExperience(int index) async {
    final current = experience;
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
      await updateProfileInfo({'experience': current});
    }
  }

  /// ================= PROFILE MEDIA =================
  Future<void> uploadProfilePicture(File file) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final url = await _profileService.uploadProfileImage(user.uid, file);
    if (url != null) {
      await updateProfileInfo({'profilePictureUrl': url});
    }
  }

  Future<String?> uploadResume(File file) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final url = await _profileService.uploadResume(user.uid, file);
    if (url != null) {
      await updateProfileInfo({'resumeUrl': url});
    }
    return url;
  }

  /// ================= OTHER PROFILE HELPERS =================
  Future<void> updateFullName(String name) async => await updateProfileInfo({'fullName': name});
  Future<void> updatePhone(String phone) async => await updateProfileInfo({'phone': phone});
  Future<void> updateLocation(String location) async => await updateProfileInfo({'location': location});
  Future<void> updateAbout(String about) async => await updateProfileInfo({'about': about});
  Future<void> updateLinks({String? linkedin, String? git, String? web}) async {
    Map<String, dynamic> data = {};
    if (linkedin != null) data['linkedIn'] = linkedin;
    if (git != null) data['github'] = git;
    if (web != null) data['website'] = web;
    await updateProfileInfo(data);
  }
}
