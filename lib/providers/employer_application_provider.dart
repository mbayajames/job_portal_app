// lib/providers/employer_application_provider.dart
import 'package:flutter/material.dart';
import '../models/application_model.dart';
import '../services/account_service.dart';
import '../services/employer_application_service.dart';

class EmployerApplicationProvider extends ChangeNotifier {
  List<ApplicationModel> _applications = [];
  List<ApplicationModel> get applications => _applications;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch applications from backend/service
  /// Optionally pass `employerId` to filter applications for this employer
  Future<void> fetchApplications({String? employerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applications = await EmployerApplicationService.getApplications() ?? [];
    } catch (e) {
      _applications = [];
      _errorMessage = 'Failed to fetch applications: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update application status (for employer)
  Future<void> updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      final success = await AccountService().updateApplicationStatus(
        applicationId: applicationId,
        status: newStatus,
      );

      if (success) {
        final index = _applications.indexWhere((app) => app.id == applicationId);
        if (index != -1) {
          _applications[index] = _applications[index].copyWith(status: newStatus);
          notifyListeners();
        }
      } else {
        _errorMessage = 'Failed to update application status.';
        debugPrint(_errorMessage);
      }
    } catch (e) {
      _errorMessage = 'Error updating application status: $e';
      debugPrint(_errorMessage);
    }
  }
}
