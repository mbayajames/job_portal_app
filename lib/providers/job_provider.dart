import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/job_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobProvider with ChangeNotifier {
  final Logger _logger = Logger('JobProvider');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ------------------------------
  // STATE
  // ------------------------------
  List<JobModel> _jobsForApplicants = [];
  List<JobModel> _myJobs = [];
  List<Map<String, dynamic>> _appliedJobs = [];
  List<Map<String, dynamic>> _jobApplications = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMoreJobs = true;
  DocumentSnapshot? _lastDocument;

  StreamSubscription<QuerySnapshot>? _applicantJobsSubscription;
  StreamSubscription<QuerySnapshot>? _employerJobsSubscription;
  StreamSubscription<QuerySnapshot>? _appliedJobsSubscription;

  // ------------------------------
  // GETTERS
  // ------------------------------
  List<JobModel> get jobsForApplicants => List.unmodifiable(_jobsForApplicants);
  List<JobModel> get myJobs => List.unmodifiable(_myJobs);
  List<Map<String, dynamic>> get appliedJobs => List.unmodifiable(_appliedJobs);
  List<Map<String, dynamic>> get jobApplications => List.unmodifiable(_jobApplications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreJobs => _hasMoreJobs;

  // ------------------------------
  // FETCH ALL OPEN JOBS FOR SEEKERS (REAL-TIME)
  // ------------------------------
  void fetchJobsForApplicants() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _logger.fine('Fetching ALL open jobs for applicants...');

    _applicantJobsSubscription?.cancel();
    _applicantJobsSubscription = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _jobsForApplicants = snapshot.docs.map(_jobFromDoc).toList();
      _isLoading = false;
      _hasMoreJobs = snapshot.docs.isNotEmpty;
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      notifyListeners();
      _logger.fine('Fetched ${_jobsForApplicants.length} jobs for seekers');
    }, onError: (e) {
      _handleError('Error fetching jobs for applicants', e);
    });
  }

  // ------------------------------
  // FETCH APPLIED JOBS FOR SEEKER (REAL-TIME)
  // ------------------------------
  void fetchAppliedJobs(String seekerId) {
    _logger.fine('Fetching applied jobs for seeker $seekerId');

    _appliedJobsSubscription?.cancel();
    _appliedJobsSubscription = _firestore
        .collection('applications')
        .where('applicantId', isEqualTo: seekerId)
        .snapshots()
        .listen((snapshot) {
      _appliedJobs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['jobId'] ?? '',
          'status': data['status'] ?? 'Applied',
          'appliedDate': data['appliedAt'],
        };
      }).toList();
      notifyListeners();
      _logger.fine('Fetched ${_appliedJobs.length} applied jobs for seeker');
    }, onError: (e) {
      _handleError('Error fetching applied jobs', e);
    });
  }

  // ------------------------------
  // PAGINATED JOBS FOR SEEKERS
  // ------------------------------
  Future<void> loadJobs({
    int page = 1,
    int limit = 10,
    String? searchQuery,
    String? filter,
    String? sort,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('jobs').where('status', isEqualTo: 'open');

      if (filter != null && filter != 'All') {
        query = query.where('employmentType', isEqualTo: filter);
      }

      if (sort == 'Salary: High to Low') {
        query = query.orderBy('salaryRange', descending: true);
      } else if (sort == 'Salary: Low to High') {
        query = query.orderBy('salaryRange');
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      query = query.limit(limit);
      if (page > 1 && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      var newJobs = snapshot.docs.map(_jobFromDoc).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        newJobs = newJobs.where((job) =>
            job.title.toLowerCase().contains(q) ||
            job.description.toLowerCase().contains(q) ||
            job.company.toLowerCase().contains(q) ||
            job.location.toLowerCase().contains(q) ||
            job.industry.toLowerCase().contains(q)).toList();
      }

      if (page == 1) {
        _jobsForApplicants = newJobs;
      } else {
        _jobsForApplicants.addAll(newJobs);
      }

      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDocument;
      _hasMoreJobs = snapshot.docs.length == limit;
      _isLoading = false;
      notifyListeners();

      _logger.fine('Loaded page $page, total jobs: ${_jobsForApplicants.length}');
    } catch (e) {
      _handleError('Error loading paginated jobs', e);
    }
  }

  // ------------------------------
  // FETCH EMPLOYER'S OWN JOBS (REAL-TIME)
  // ------------------------------
  void fetchMyJobs(String employerId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _logger.fine('Fetching jobs for employer $employerId');

    _employerJobsSubscription?.cancel();

    try {
      Query query = _firestore
          .collection('jobs')
          .where('employerId', isEqualTo: employerId)
          .orderBy('createdAt', descending: true);

      _employerJobsSubscription = query.snapshots().listen((snapshot) {
        _myJobs = snapshot.docs.map(_jobFromDoc).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
        _logger.fine('Successfully fetched ${_myJobs.length} employer jobs');
      }, onError: (e) {
        _logger.warning('Indexed query failed, trying fallback: $e');
        _tryFallbackQuery(employerId);
      });
    } catch (e) {
      _logger.warning('Query setup failed, trying fallback: $e');
      _tryFallbackQuery(employerId);
    }
  }

  void _tryFallbackQuery(String employerId) {
    _logger.fine('Attempting fallback query without ordering');

    Query fallbackQuery = _firestore.collection('jobs').where('employerId', isEqualTo: employerId);

    _employerJobsSubscription?.cancel();
    _employerJobsSubscription = fallbackQuery.snapshots().listen((snapshot) {
      try {
        var jobs = snapshot.docs.map(_jobFromDoc).toList();
        jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _myJobs = jobs;
        _isLoading = false;
        _error = null;
        notifyListeners();
        _logger.fine('Fallback query successful: ${_myJobs.length} jobs');
      } catch (sortError) {
        _myJobs = snapshot.docs.map(_jobFromDoc).toList();
        _isLoading = false;
        _error = 'Data loaded but sorting failed: $sortError';
        notifyListeners();
        _logger.warning('Sorting failed but jobs loaded: $sortError');
      }
    }, onError: (e) {
      _handleError('Both primary and fallback queries failed', e);
    });
  }

  // ------------------------------
  // ADD / UPDATE / DELETE JOBS
  // ------------------------------
  Future<void> addJob(JobModel job) async {
    try {
      final docRef = await _firestore.collection('jobs').add({
        ...job.toMap(),
        'status': 'open',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final newJob = job.copyWith(id: docRef.id, status: 'open');
      _myJobs.insert(0, newJob);
      notifyListeners();

      fetchJobsForApplicants();
    } catch (e) {
      _handleError('Error adding job', e);
    }
  }

  Future<void> updateJob(JobModel job) async {
    try {
      await _firestore.collection('jobs').doc(job.id).update({
        ...job.toMap(),
        'updatedAt': Timestamp.now(),
      });

      final index = _myJobs.indexWhere((j) => j.id == job.id);
      if (index != -1) _myJobs[index] = job;
      notifyListeners();

      fetchJobsForApplicants();
    } catch (e) {
      _handleError('Error updating job', e);
    }
  }

  Future<void> removeJob(String jobId) async {
    try {
      final batch = _firestore.batch();

      final applicationsSnapshot =
          await _firestore.collection('applications').where('jobId', isEqualTo: jobId).get();

      for (var doc in applicationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_firestore.collection('jobs').doc(jobId));
      await batch.commit();

      _myJobs.removeWhere((job) => job.id == jobId);
      notifyListeners();

      fetchJobsForApplicants();
    } catch (e) {
      _handleError('Error deleting job', e);
    }
  }

  // ------------------------------
  // APPLY TO JOB (SEEKER)
  // ------------------------------
  Future<void> applyToJob(String jobId, String applicantId, {Map<String, dynamic>? applicationData}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User is not authenticated';
      }
      if (applicantId != user.uid) {
        throw 'Applicant ID does not match authenticated user';
      }

      _logger.fine('Applying to job with data: jobId=$jobId, applicantId=$applicantId, applicationData=$applicationData');

      final existingApplication = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('applicantId', isEqualTo: applicantId)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        throw 'You have already applied to this job';
      }

      final applicationDoc = {
        'jobId': jobId,
        'applicantId': applicantId,
        'status': 'Applied',
        'appliedAt': Timestamp.now(),
        ...?applicationData,
      };
      _logger.fine('Application document: $applicationDoc');

      // Step 1: Create application
      _logger.fine('Creating application document...');
      await _firestore.collection('applications').add(applicationDoc);

      // Step 2: Update application count
      _logger.fine('Updating application count for job $jobId...');
      await _firestore.collection('jobs').doc(jobId).update({
        'applicationCount': FieldValue.increment(1),
      });

      _logger.fine('Successfully applied to job $jobId');
      notifyListeners();
    } catch (e) {
      _handleError('Error applying to job', e);
      rethrow;
    }
  }

  // ------------------------------
  // GET SINGLE JOB BY ID
  // ------------------------------
  Future<JobModel?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (doc.exists) {
        return _jobFromDoc(doc);
      }
      return null;
    } catch (e) {
      _handleError('Error fetching job by ID', e);
      return null;
    }
  }

  // ------------------------------
  // FETCH APPLICATIONS FOR A SPECIFIC JOB (EMPLOYER VIEW)
  // ------------------------------
  Future<void> fetchApplicationsForJob(String jobId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.fine('🔍 Fetching applications for job: $jobId');

      QuerySnapshot applicationsSnapshot;

      // First, try to get applications without ordering
      applicationsSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .get();

      _logger.fine('📊 Found ${applicationsSnapshot.docs.length} applications (no ordering)');

      if (applicationsSnapshot.docs.isEmpty) {
        _logger.warning('⚠️ No applications found for jobId: $jobId');
        _jobApplications = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check what date field exists
      final firstDoc = applicationsSnapshot.docs.first.data() as Map<String, dynamic>;
      final hasAppliedAt = firstDoc.containsKey('appliedAt');
      final hasAppliedDate = firstDoc.containsKey('appliedDate');

      _logger.fine('📝 Date field check: hasAppliedAt=$hasAppliedAt, hasAppliedDate=$hasAppliedDate');

      if (hasAppliedAt) {
        try {
          applicationsSnapshot = await _firestore
              .collection('applications')
              .where('jobId', isEqualTo: jobId)
              .orderBy('appliedAt', descending: true)
              .get();
          _logger.fine('✅ Successfully ordered by appliedAt');
        } catch (e) {
          _logger.warning('⚠️ Could not order by appliedAt, using unordered results: $e');
        }
      } else if (hasAppliedDate) {
        try {
          applicationsSnapshot = await _firestore
              .collection('applications')
              .where('jobId', isEqualTo: jobId)
              .orderBy('appliedDate', descending: true)
              .get();
          _logger.fine('✅ Successfully ordered by appliedDate');
        } catch (e) {
          _logger.warning('⚠️ Could not order by appliedDate, using unordered results: $e');
        }
      }

      final applications = await Future.wait(applicationsSnapshot.docs.map((doc) async {
        try {
          final appData = doc.data() as Map<String, dynamic>;
          final applicantId = appData['applicantId'] as String;

          _logger.fine('👤 Processing application for applicant: $applicantId');

          DocumentSnapshot userDoc;
          Map<String, dynamic> userData = {};

          try {
            userDoc = await _firestore.collection('users').doc(applicantId).get();
            if (userDoc.exists) {
              userData = userDoc.data() as Map<String, dynamic>;
              _logger.fine('✅ Found user data for: $applicantId');
            } else {
              _logger.warning('⚠️ User document not found for: $applicantId');
            }
          } catch (e) {
            _logger.warning('⚠️ Error fetching user data for $applicantId: $e');
          }

          return {
            'id': doc.id,
            'jobId': appData['jobId'] ?? jobId,
            'applicantId': applicantId,
            'applicantName': userData['fullName'] ?? userData['name'] ?? userData['displayName'] ?? 'Unknown Applicant',
            'applicantEmail': userData['email'] ?? '',
            'applicantPhone': userData['phoneNumber'] ?? userData['phone'] ?? '',
            'applicantPhoto': userData['profilePicture'] ?? userData['photoURL'],
            'status': appData['status'] ?? 'Applied',
            'appliedAt': appData['appliedAt'] ?? appData['appliedDate'],
            'reviewedAt': appData['reviewedAt'],
            'notes': appData['notes'],
            'coverLetter': appData['coverLetter'],
            'resume': appData['resume'],
            'resumeUrl': appData['resumeUrl'],
            ...appData,
          };
        } catch (e) {
          _logger.severe('❌ Error processing application ${doc.id}: $e');
          final appData = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'jobId': appData['jobId'] ?? jobId,
            'applicantId': appData['applicantId'] ?? 'Unknown',
            'applicantName': 'Error Loading Applicant',
            'status': appData['status'] ?? 'Applied',
            'appliedAt': appData['appliedAt'] ?? appData['appliedDate'],
            ...appData,
          };
        }
      }).toList());

      // Sort by appliedAt in memory
      applications.sort((a, b) {
        final aDate = a['appliedAt'];
        final bDate = b['appliedAt'];

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        if (aDate is Timestamp && bDate is Timestamp) {
          return bDate.compareTo(aDate);
        }

        if (aDate is DateTime && bDate is DateTime) {
          return bDate.compareTo(aDate);
        }

        return 0;
      });

      _jobApplications = applications;
      _isLoading = false;
      notifyListeners();

      _logger.fine('✅ Successfully loaded ${applications.length} applications for job $jobId');
    } catch (e) {
      _handleError('Error fetching applications for job', e);
    }
  }

  // ------------------------------
  // FETCH APPLICATIONS (RETURNS FUTURE)
  // ------------------------------
  Future<List<Map<String, dynamic>>> fetchApplications(String jobId) async {
    await fetchApplicationsForJob(jobId);
    return List.unmodifiable(_jobApplications);
  }

  // ------------------------------
  // UPDATE APPLICATION STATUS
  // ------------------------------
  Future<void> updateApplicationStatus(String applicationId, String newStatus, {String? notes}) async {
    try {
      final updateData = {
        'status': newStatus,
        'reviewedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _firestore.collection('applications').doc(applicationId).update(updateData);

      final index = _jobApplications.indexWhere((app) => app['id'] == applicationId);
      if (index != -1) {
        _jobApplications[index] = {
          ..._jobApplications[index],
          'status': newStatus,
          'reviewedAt': Timestamp.now(),
          'notes': notes ?? _jobApplications[index]['notes'],
        };
        notifyListeners();
      }

      _logger.fine('Updated application $applicationId status to $newStatus');
    } catch (e) {
      _handleError('Error updating application status', e);
      rethrow;
    }
  }

  // ------------------------------
  // APPROVE APPLICATION
  // ------------------------------
  Future<void> approveApplication(String applicationId, {String? notes}) async {
    await updateApplicationStatus(applicationId, 'Approved', notes: notes);
  }

  // ------------------------------
  // REJECT APPLICATION
  // ------------------------------
  Future<void> rejectApplication(String applicationId, {String? notes}) async {
    await updateApplicationStatus(applicationId, 'Rejected', notes: notes);
  }

  // ------------------------------
  // HIRE APPLICANT
  // ------------------------------
  Future<void> hireApplicant(String applicationId, {String? notes}) async {
    await updateApplicationStatus(applicationId, 'Hired', notes: notes);
  }

  // ------------------------------
  // HELPER METHODS
  // ------------------------------
  JobModel _jobFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel.fromMap(data, doc.id);
  }

  void _handleError(String message, Object e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    _logger.severe(message, e);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearJobsForApplicants() {
    _jobsForApplicants.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _applicantJobsSubscription?.cancel();
    _employerJobsSubscription?.cancel();
    _appliedJobsSubscription?.cancel();
    super.dispose();
  }
}
