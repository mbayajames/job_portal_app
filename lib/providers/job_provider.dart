import 'package:flutter/material.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';

class JobProvider with ChangeNotifier {
  final JobService _jobService = JobService();
  Stream<List<JobModel>> _jobsStream = Stream.value([]);
  Map<String, dynamic> _currentFilters = {};

  Stream<List<JobModel>> get jobsStream => _jobsStream;

  JobProvider() {
    _jobsStream = _jobService.getJobsStream();
  }

  void searchJobs(String query) {
    _currentFilters['query'] = query.trim().toLowerCase();
    _applyFilters();
  }

  void filterJobs({
    String category = '',
    String jobType = '',
    String location = '',
    String salaryRange = '',
    String sortOption = 'Newest',
  }) {
    _currentFilters = {
      'category': category.toLowerCase(),
      'jobType': jobType.toLowerCase(),
      'location': location.toLowerCase(),
      'salaryRange': salaryRange.toLowerCase(),
      'sortOption': sortOption,
    };
    _applyFilters();
  }

  void resetFilters() {
    _currentFilters = {};
    _jobsStream = _jobService.getJobsStream();
    notifyListeners();
  }

  void _applyFilters() {
    _jobsStream = _jobService.getJobsStream().map((jobs) {
      var filteredJobs = jobs.where((job) {
        final query = _currentFilters['query'] ?? '';
        final category = _currentFilters['category'] ?? '';
        final jobType = _currentFilters['jobType'] ?? '';
        final location = _currentFilters['location'] ?? '';
        final salaryRange = _currentFilters['salaryRange'] ?? '';

        bool matchesQuery = query.isEmpty ||
            job.title.toLowerCase().contains(query) ||
            job.companyName.toLowerCase().contains(query);

        bool matchesCategory = category.isEmpty || job.category?.toLowerCase() == category;
        bool matchesJobType = jobType.isEmpty || job.jobType.toLowerCase() == jobType;
        bool matchesLocation = location.isEmpty || job.location.toLowerCase().contains(location);
        bool matchesSalary = salaryRange.isEmpty || job.salaryRange.toLowerCase() == salaryRange;

        return matchesQuery && matchesCategory && matchesJobType && matchesLocation && matchesSalary;
      }).toList();

      if (_currentFilters['sortOption'] == 'Salary High to Low') {
        filteredJobs.sort((a, b) {
          int aSalary = int.tryParse(a.salaryRange.split('-').last.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
          int bSalary = int.tryParse(b.salaryRange.split('-').last.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
          return bSalary.compareTo(aSalary);
        });
      } else if (_currentFilters['sortOption'] == 'Salary Low to High') {
        filteredJobs.sort((a, b) {
          int aSalary = int.tryParse(a.salaryRange.split('-').first.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
          int bSalary = int.tryParse(b.salaryRange.split('-').first.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
          return aSalary.compareTo(bSalary);
        });
      } else {
        filteredJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      return filteredJobs;
    });
    notifyListeners();
  }
}