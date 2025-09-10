import 'package:flutter/foundation.dart';
import '../models/job_model.dart';

class JobProvider extends ChangeNotifier {
  List<JobModel> _jobs = [];

  List<JobModel> get jobs => _jobs;

  void updateJobs(List<JobModel> jobs) {
    _jobs = jobs;
    notifyListeners();
  }
}
