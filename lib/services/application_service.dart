import '../models/application_model.dart';
import 'api_service.dart';

class ApplicationService {
  final ApiService _apiService = ApiService();

  Future<List<Application>> fetchApplications() async {
    return await _apiService.getApplications();
  }

  Future<Application> submitApplication(Application application) async {
    return await _apiService.submitApplication(application.jobId, application.toMap());
  }
}