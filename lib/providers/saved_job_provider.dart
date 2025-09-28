import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saved_job_model.dart';
import '../services/api_service.dart';
import '../services/job_service.dart';

class SavedJobProvider with ChangeNotifier {
  List<SavedJob> _savedJobs = [];
  bool _isLoading = false;
  String? _error;

  List<SavedJob> get savedJobs => _savedJobs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();
  final JobService _jobService = JobService();

  Future<void> loadSavedJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _savedJobs = await _apiService.getSavedJobs();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveJob(String jobId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final jobModel = await _jobService.getJobById(jobId);
      if (jobModel == null) return;
      final job = Job(
        id: jobModel.id,
        title: jobModel.title,
        company: jobModel.company,
        location: jobModel.location,
        type: jobModel.employmentType,
        salary: _parseSalary(jobModel.salaryRange),
        description: jobModel.description,
        requirements: jobModel.requirements,
        skills: jobModel.requirements,
        postedDate: jobModel.createdAt,
        experienceLevel: jobModel.experienceLevel,
        industry: jobModel.industry,
      );
      final savedJob = SavedJob(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobId: jobId,
        userId: user.uid,
        savedAt: DateTime.now(),
        jobDetails: job,
      );
      await _apiService.saveJob(jobId);
      _savedJobs.add(savedJob);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> unsaveJob(String savedJobId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _apiService.unsaveJob(savedJobId);
      _savedJobs.removeWhere((job) => job.id == savedJobId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isJobSaved(String jobId) {
    return _savedJobs.any((job) => job.jobId == jobId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  double _parseSalary(String salaryRange) {
    final reg = RegExp(r'(\d+(?:,\d+)*)');
    final matches = reg.allMatches(salaryRange);
    if (matches.isEmpty) return 0.0;
    final numbers = matches.map((m) => double.tryParse(m.group(1)?.replaceAll(',', '') ?? '0') ?? 0.0).toList();
    return numbers.isNotEmpty ? numbers.reduce((a, b) => a + b) / numbers.length : 0.0;
  }
}