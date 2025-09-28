// lib/services/api_service.dart
import '../models/user_model.dart';
import '../models/saved_job_model.dart';
import '../models/application_model.dart';

class ApiService {
  static const String baseUrl = 'https://your-api-domain.com/api';
  final String? token;

  ApiService({this.token});

  // ------------------------------
  // USER
  // ------------------------------
  Future<UserModel> getUserProfile(String userId) async {
    // Simulated API call
    await Future.delayed(const Duration(seconds: 1));

    return UserModel(
      id: 'user_123',
      email: 'john.doe@example.com',
      fullName: 'John Doe',
      role: 'seeker',
      phone: '+1234567890',
      education: [
        Education(
          institution: 'University of Example',
          degree: 'Bachelor of Science',
          field: 'Computer Science',
          startDate: DateTime(2018, 9, 1),
          endDate: DateTime(2022, 6, 1),
          isCurrent: false,
        ),
      ],
      experience: [
        WorkExperience(
          company: 'Tech Company',
          position: 'Software Developer',
          description: 'Developed mobile applications',
          startDate: DateTime(2022, 7, 1),
          endDate: null,
          isCurrent: true,
        ),
      ],
      skills: ['Flutter', 'Dart', 'Firebase', 'REST API'],
      preferences: CareerPreferences(
        jobType: 'Full-time',
        preferredLocation: 'Remote',
        minSalary: 60000,
        preferredIndustries: ['Technology', 'Software Development'],
        experienceLevel: 'Mid-level',
      ),
    );
  }

  Future<UserModel> updateUserProfile(UserModel user) async {
    await Future.delayed(const Duration(seconds: 2));
    return user;
  }

  Future<String> uploadFile(String filePath) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'https://your-api-domain.com/files/${DateTime.now().millisecondsSinceEpoch}';
  }

  // ------------------------------
  // JOBS
  // ------------------------------

  /// ✅ Post a job (with employerId included)
  Future<Map<String, dynamic>> postJob(Map<String, dynamic> jobData) async {
    await Future.delayed(const Duration(seconds: 2));

    final newJob = {
      'id': 'job_${DateTime.now().millisecondsSinceEpoch}',
      ...jobData,
      'employerId': jobData['employerId'], // ✅ ensure employer link
      'createdAt': DateTime.now().toIso8601String(),
    };

    return newJob;
  }

  Future<List<SavedJob>> getSavedJobs() async {
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }

  Future<SavedJob> saveJob(String jobId) async {
    await Future.delayed(const Duration(seconds: 1));
    return SavedJob(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      jobId: jobId,
      userId: 'user_123',
      savedAt: DateTime.now(),
      jobDetails: Job(
        id: jobId,
        title: 'Sample Job',
        company: 'Sample Company',
        location: 'Remote',
        type: 'Full-time',
        salary: 70000,
        description: 'Job description',
        requirements: ['Requirement 1', 'Requirement 2'],
        skills: ['Skill 1', 'Skill 2'],
        postedDate: DateTime.now(),
        experienceLevel: 'Mid-level',
        industry: 'Technology',
      ),
    );
  }

  Future<void> unsaveJob(String savedJobId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  // ------------------------------
  // APPLICATIONS
  // ------------------------------
  Future<List<Application>> getApplications() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      Application(
        id: '1',
        jobId: '1',
        jobTitle: 'Flutter Developer',
        companyId: 'comp_1',
        companyName: 'Tech Corp',
        applicantId: 'user_123',
        applicantName: 'John Doe',
        applicantEmail: 'john.doe@example.com',
        resumeUrl: 'https://your-api-domain.com/resume/john.pdf',
        coverLetter: 'I am excited to apply for this position.',
        status: 'pending',
        appliedDate: DateTime.now().subtract(const Duration(days: 1)),
        additionalAnswers: {},
        location: 'Remote',
        jobType: 'Full-time',
        statusHistory: [],
        userId: 'user_123',
        applicationData: {},
        isPaid: false,
        email: 'john.doe@example.com',
        phone: '+1234567890',
        salary: 70000,
      ),
      Application(
        id: '2',
        jobId: '2',
        jobTitle: 'Senior Flutter Developer',
        companyId: 'comp_2',
        companyName: 'Another Company',
        applicantId: 'user_123',
        applicantName: 'John Doe',
        applicantEmail: 'john.doe@example.com',
        resumeUrl: 'https://your-api-domain.com/resume/john.pdf',
        coverLetter: 'I am very interested in this position.',
        status: 'under_review',
        appliedDate: DateTime.now().subtract(const Duration(days: 3)),
        additionalAnswers: {},
        location: 'Remote',
        jobType: 'Full-time',
        statusHistory: [],
        userId: 'user_123',
        applicationData: {},
        isPaid: false,
        email: 'john.doe@example.com',
        phone: '+1234567890',
        salary: 80000,
      ),
    ];
  }

  /// ✅ Submit an application (ensure jobId & applicantId are included)
  Future<Application> submitApplication(
    String jobId,
    Map<String, dynamic> applicationData,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    return Application(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      jobId: jobId,
      jobTitle: applicationData['jobTitle'] ?? 'Unknown',
      companyId: applicationData['companyId'] ?? 'comp_1',
      companyName: applicationData['companyName'] ?? 'Tech Corp',
      applicantId: applicationData['applicantId'] ?? 'user_123', // ✅ ensure applicant link
      applicantName: applicationData['applicantName'] ?? 'John Doe',
      applicantEmail: applicationData['applicantEmail'] ?? 'john.doe@example.com',
      resumeUrl: applicationData['resumeUrl'] ?? '',
      coverLetter: applicationData['coverLetter'] ?? '',
      status: 'pending',
      appliedDate: DateTime.now(),
      additionalAnswers: applicationData['additionalAnswers'] ?? {},
      location: applicationData['location'] ?? 'Remote',
      jobType: applicationData['jobType'] ?? 'Full-time',
      statusHistory: [],
      userId: applicationData['userId'] ?? 'user_123',
      applicationData: applicationData,
      isPaid: applicationData['isPaid'] ?? false,
      email: applicationData['applicantEmail'] ?? 'john.doe@example.com',
      phone: applicationData['phone'] ?? '+1234567890',
      salary: (applicationData['salary'] ?? 0).toDouble(),
    );
  }

  Future<void> withdrawApplication(String applicationId) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
