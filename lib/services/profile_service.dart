import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';
import '../models/profile_model.dart';

class ProfileService {
  final Logger _logger = Logger('ProfileService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Fetch profile by user ID
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return ProfileModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      _logger.severe("Error fetching profile: $e");
    }
    return null;
  }

  /// Update profile info in Firestore
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  /// Upload resume to Firebase Storage and return download URL
  Future<String?> uploadResume(String userId, File file) async {
    try {
      final ref = _storage.ref().child(
          'resumes/$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _logger.severe("Error uploading resume: $e");
      return null;
    }
  }

  /// Upload profile image to Firebase Storage and return download URL
  Future<String?> uploadProfileImage(String userId, File file) async {
    try {
      final ref = _storage.ref().child(
          'profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _logger.severe("Error uploading profile image: $e");
      return null;
    }
  }

  /// Add skills to the profile
  Future<void> addSkills(String userId, List<String> skills) async {
    await _firestore.collection('users').doc(userId).set({
      'skills': FieldValue.arrayUnion(skills),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update applied jobs
  Future<void> updateAppliedJobs(String userId, String jobId) async {
    await _firestore.collection('users').doc(userId).set({
      'appliedJobs': FieldValue.arrayUnion([jobId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update saved jobs
  Future<void> updateSavedJobs(String userId, String jobId) async {
    await _firestore.collection('users').doc(userId).set({
      'savedJobs': FieldValue.arrayUnion([jobId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
