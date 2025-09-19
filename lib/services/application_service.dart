import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'notification_service.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Submit a job application
  Future<void> submitApplication({
    required String userId,
    required String jobId,
    required Map<String, dynamic> details,
    required String resumeUrl,
    String? coverLetterUrl,
    required Map<String, String> questionAnswers,
  }) async {
    try {
      final applicationId = _firestore.collection('applications').doc().id;
      await _firestore.collection('applications').doc(applicationId).set({
        'userId': userId,
        'jobId': jobId,
        'details': details,
        'resumeUrl': resumeUrl,
        'coverLetterUrl': coverLetterUrl,
        'questionAnswers': questionAnswers,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify employer
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final employerId = jobDoc.data()?['employerId'];
      if (employerId != null) {
        await _notificationService.sendNotification(
          employerId,
          'New Application',
          'New application received for job: ${jobDoc.data()?['title']}',
        );
      }
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Upload file to Firebase Storage
  Future<String?> uploadFile(String userId, String filePath, String folder) async {
    try {
      final ref = _storage.ref().child('$folder/$userId/${DateTime.now().millisecondsSinceEpoch}.pdf');
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Fetch applications for a user (seeker)
  Stream<List<Map<String, dynamic>>> getUserApplications(String userId) => _firestore
      .collection('applications')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {
            ...doc.data(),
            'id': doc.id,
          }).toList());

  // Fetch applications for a job (employer)
  Stream<List<Map<String, dynamic>>> getJobApplications(String jobId) => _firestore
      .collection('applications')
      .where('jobId', isEqualTo: jobId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {
            ...doc.data(),
            'id': doc.id,
          }).toList());

  // Update application status
  Future<void> updateApplicationStatus(String applicationId, String status, String userId, String jobId) async {
    try {
      await _firestore.collection('applications').doc(applicationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify user
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      await _notificationService.sendNotification(
        userId,
        'Application Status Update',
        'Your application for ${jobDoc.data()?['title']} has been updated to: $status',
      );
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }
}