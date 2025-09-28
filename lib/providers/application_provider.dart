// lib/providers/application_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/application_model.dart';
import '../models/job_model.dart';

class ApplicationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Application> _applications = [];
  bool _isLoading = false;
  String? _error;

  // ----------------------------
  // 🔹 Getters
  // ----------------------------
  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ----------------------------
  // 🔹 Load applications (all)
  // ----------------------------
  Future<void> loadApplications({String? applicantId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _firestore.collection('applications');
      if (applicantId != null) {
        query = query.where('applicantId', isEqualTo: applicantId);
      }

      final snapshot = await query.orderBy('appliedDate', descending: true).get();

      _applications = await Future.wait(snapshot.docs.map((doc) async {
        final appData = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        JobModel? job;

        if (appData['jobId'] != null) {
          final jobDoc = await _firestore.collection('jobs').doc(appData['jobId']).get();
          if (jobDoc.exists) {
            job = JobModel.fromMap(jobDoc.data() as Map<String, dynamic>, jobDoc.id);
          }
        }

        return Application.fromJson(appData).copyWith(job: job);
      }).toList());
    } catch (e) {
      _error = 'Error loading applications: $e';
      debugPrint('Firestore Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // 🔹 Load applications with pagination
  // ----------------------------
  Future<void> loadApplicationsPaginated({String? applicantId, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _firestore.collection('applications');
      if (applicantId != null) {
        query = query.where('applicantId', isEqualTo: applicantId);
      }

      final querySnapshot = await query.limit(limit).get();

      _applications = await Future.wait(querySnapshot.docs.map((doc) async {
        final appData = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        JobModel? job;

        if (appData['jobId'] != null) {
          final jobDoc = await _firestore.collection('jobs').doc(appData['jobId']).get();
          if (jobDoc.exists) {
            job = JobModel.fromMap(jobDoc.data() as Map<String, dynamic>, jobDoc.id);
          }
        }

        return Application.fromJson(appData).copyWith(job: job);
      }).toList());

      _applications.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
    } catch (e) {
      _error = 'Error loading applications: $e';
      debugPrint('Firestore Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // 🔹 Submit new application
  // ----------------------------
  Future<void> submitApplication({
    required String jobId,
    required String applicantId,
    required Map<String, dynamic> applicationData,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = _firestore.collection('applications').doc();

      final application = {
        'id': docRef.id,
        'jobId': jobId,
        'applicantId': applicantId,
        'status': 'Applied',
        'appliedDate': Timestamp.now(),
        'updatedDate': Timestamp.now(),
        ...applicationData,
      };

      await docRef.set(application);

      JobModel? job;
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists) {
        job = JobModel.fromMap(jobDoc.data() as Map<String, dynamic>, jobDoc.id);
      }

      _applications.insert(0, Application.fromJson(application).copyWith(job: job));
      notifyListeners();
    } catch (e) {
      _error = 'Error submitting application: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // ----------------------------
  // 🔹 Apply for job (simpler)
  // ----------------------------
  Future<void> applyForJob({
    required String jobId,
    required String jobTitle,
    required String companyId,
    required String companyName,
    required String applicantId,
    required String applicantName,
    required String applicantEmail,
    required String resumeUrl,
    String coverLetter = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = _firestore.collection('applications').doc();

      final applicationData = {
        'id': docRef.id,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'companyId': companyId,
        'companyName': companyName,
        'applicantId': applicantId,
        'applicantName': applicantName,
        'applicantEmail': applicantEmail,
        'resumeUrl': resumeUrl,
        'coverLetter': coverLetter,
        'status': 'Applied',
        'appliedDate': Timestamp.now(),
        'updatedDate': Timestamp.now(),
      };

      await docRef.set(applicationData);

      // Fetch job
      JobModel? job;
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists) {
        job = JobModel.fromMap(jobDoc.data() as Map<String, dynamic>, jobDoc.id);
      }

      _applications.insert(0, Application.fromJson(applicationData).copyWith(job: job));
      notifyListeners();
    } catch (e) {
      _error = 'Error applying for job: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  // ----------------------------
  // 🔹 Withdraw application
  // ----------------------------
  Future<void> withdrawApplication(String applicationId) async {
    try {
      await _firestore.collection('applications').doc(applicationId).update({
        'status': 'Withdrawn',
        'updatedDate': Timestamp.now(),
      });

      final index = _applications.indexWhere((app) => app.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(
          status: 'Withdrawn',
          updatedDate: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error withdrawing application: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ----------------------------
  // 🔹 Update application status
  // ----------------------------
  Future<void> updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await _firestore.collection('applications').doc(applicationId).update({
        'status': newStatus,
        'updatedDate': Timestamp.now(),
      });

      final index = _applications.indexWhere((app) => app.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(
          status: newStatus,
          updatedDate: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating status: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ----------------------------
  // 🔹 Toggle favorite
  // ----------------------------
  Future<void> toggleFavorite(String applicationId) async {
    try {
      final index = _applications.indexWhere((app) => app.id == applicationId);
      if (index != -1) {
        final newFavoriteStatus = !_applications[index].isFavorite;
        await _firestore.collection('applications').doc(applicationId).update({
          'isFavorite': newFavoriteStatus,
          'updatedDate': Timestamp.now(),
        });

        _applications[index] = _applications[index].copyWith(
          isFavorite: newFavoriteStatus,
          updatedDate: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error toggling favorite: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ----------------------------
  // 🔹 Real-time stream of applications
  // ----------------------------
  Stream<List<Application>> getApplicationsStream(String applicantId) {
    return _firestore
        .collection('applications')
        .where('applicantId', isEqualTo: applicantId)
        .snapshots()
        .asyncMap((snapshot) async {
      final apps = await Future.wait(snapshot.docs.map((doc) async {
        final appData = {'id': doc.id, ...doc.data()};
        JobModel? job;

        if (appData['jobId'] != null) {
          final jobDoc = await _firestore.collection('jobs').doc(appData['jobId']).get();
          if (jobDoc.exists) {
            job = JobModel.fromMap(jobDoc.data() as Map<String, dynamic>, jobDoc.id);
          }
        }

        return Application.fromJson(appData).copyWith(job: job);
      }).toList());

      apps.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
      return apps;
    });
  }

  // ----------------------------
  // 🔹 Utility methods
  // ----------------------------
  Application? getApplicationById(String applicationId) {
    try {
      return _applications.firstWhere((app) => app.id == applicationId);
    } catch (_) {
      return null;
    }
  }

  List<Application> getApplicationsByStatus(String status) {
    return _applications.where((app) => app.status == status).toList();
  }

  void clearApplications() {
    _applications.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
