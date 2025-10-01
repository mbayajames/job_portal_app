import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/job_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  final JobService _jobService = JobService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  /// Current context identifiers
  String? _employerId;
  String? _userId;

  /// User-specific saved jobs
  List<String> _savedJobIds = [];

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  List<String> get savedJobIds => _savedJobIds;

  /// Set current employer context
  void setEmployerId(String employerId) {
    _employerId = employerId;
    _userId = null;
    _savedJobIds = [];
    _initialize();
  }

  /// Set current user context
  void setUserId(String userId) {
    _userId = userId;
    _employerId = null;
    _initialize();
    _loadSavedJobs();
  }

  /// Initialize notifications stream
  void _initialize() {
    if (_employerId != null) {
      _service.getEmployerNotificationsStream(_employerId!).listen((data) {
        _notifications = data;
        _unreadCount = _notifications.where((n) => !n.read).length;
        notifyListeners();
      });
    } else if (_userId != null) {
      _service.getUserNotificationsStream(_userId!).listen((data) {
        _notifications = data;
        _unreadCount = _notifications.where((n) => !n.read).length;
        notifyListeners();
      });
    }
  }

  /// Load saved jobs for the user
  Future<void> _loadSavedJobs() async {
    if (_userId == null) return;
    _savedJobIds = await _jobService.getSavedJobIdsForUser(_userId!);
    notifyListeners();
  }

  /// Mark individual notification as read
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      _unreadCount = _notifications.where((n) => !n.read).length;
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_employerId != null) {
      await _service.markAllAsRead(_employerId!);
    } else if (_userId != null) {
      await _service.markAllAsReadForUser(_userId!);
    }
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId);
    _notifications.removeWhere((n) => n.id == notificationId);
    _unreadCount = _notifications.where((n) => !n.read).length;
    notifyListeners();
  }

  // ============ EMPLOYER NOTIFICATION SENDERS ============

  /// Send notifications
  Future<void> sendNotificationToEmployer({
    required String employerId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? metadata,
  }) async {
    await _service.sendNotificationToEmployer(
      employerId: employerId,
      title: title,
      message: message,
      type: type,
      metadata: metadata,
    );
  }

  /// Notify employer on job application
  Future<void> notifyEmployerOnApplication({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String applicantName,
    required String applicantId,
  }) async {
    await _service.notifyEmployerOnApplication(
      employerId: employerId,
      jobId: jobId,
      jobTitle: jobTitle,
      applicantName: applicantName,
      applicantId: applicantId,
    );
  }

  /// Notify employer when payment is received
  Future<void> notifyEmployerPaymentReceived({
    required String employerId,
    required String amount,
    required String transactionId,
  }) async {
    await _service.notifyEmployerPaymentReceived(
      employerId: employerId,
      amount: amount,
      transactionId: transactionId,
    );
  }

  /// Notify employer when job is saved
  Future<void> notifyEmployerJobSaved({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String seekerName,
  }) async {
    await _service.notifyEmployerJobSaved(
      employerId: employerId,
      jobId: jobId,
      jobTitle: jobTitle,
      seekerName: seekerName,
    );
  }

  // ============ JOB SEEKER NOTIFICATION SENDERS ============

  /// Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? metadata,
  }) async {
    await _service.sendNotificationToUser(
      userId: userId,
      title: title,
      message: message,
      type: type,
      metadata: metadata,
    );
  }

  /// Notify user that their application was submitted
  Future<void> notifySeekerApplicationSubmitted({
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    if (_userId == null) return;
    await _service.notifySeekerApplicationSubmitted(
      userId: _userId!,
      jobTitle: jobTitle,
      companyName: companyName,
      jobId: jobId,
    );
  }

  /// Notify user they are hired
  Future<void> notifySeekerHired({
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    if (_userId == null) return;
    await _service.notifySeekerHired(
      userId: _userId!,
      jobTitle: jobTitle,
      companyName: companyName,
      jobId: jobId,
    );
  }

  /// Notify user about application status update
  Future<void> notifySeekerApplicationStatusUpdate({
    required String jobTitle,
    required String status,
    required String jobId,
  }) async {
    if (_userId == null) return;
    await _service.notifySeekerApplicationStatusUpdate(
      userId: _userId!,
      jobTitle: jobTitle,
      status: status,
      jobId: jobId,
    );
  }

  /// Notify user about interview schedule
  Future<void> notifySeekerInterviewScheduled({
    required String jobTitle,
    required String companyName,
    required DateTime interviewDate,
    required String location,
    required String jobId,
  }) async {
    if (_userId == null) return;
    await _service.notifySeekerInterviewScheduled(
      userId: _userId!,
      jobTitle: jobTitle,
      companyName: companyName,
      interviewDate: interviewDate,
      location: location,
      jobId: jobId,
    );
  }

  /// Notify user about new job match
  Future<void> notifySeekerNewJobMatch({
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    if (_userId == null) return;
    await _service.notifySeekerNewJobMatch(
      userId: _userId!,
      jobTitle: jobTitle,
      companyName: companyName,
      jobId: jobId,
    );
  }

  /// Notify user about profile update
  Future<void> notifySeekerProfileUpdated() async {
    if (_userId == null) return;
    await _service.notifySeekerProfileUpdated(userId: _userId!);
  }

  /// Notify user about settings update
  Future<void> notifySeekerSettingsUpdated() async {
    if (_userId == null) return;
    await _service.notifySeekerSettingsUpdated(userId: _userId!);
  }

  /// Notify user when saved job is closed
  Future<void> notifySeekerSavedJobClosed({
    required String jobTitle,
    required String companyName,
  }) async {
    if (_userId == null) return;
    await _service.notifySeekerSavedJobClosed(
      userId: _userId!,
      jobTitle: jobTitle,
      companyName: companyName,
    );
  }

  // ============ SAVED JOBS MANAGEMENT ============

  /// Manage saved jobs
  Future<void> saveJob(String jobId) async {
    if (_userId == null) return;
    if (!_savedJobIds.contains(jobId)) {
      _savedJobIds.add(jobId);
      await _jobService.saveJobForUser(_userId!, jobId);
      notifyListeners();
    }
  }

  Future<void> removeSavedJob(String jobId) async {
    if (_userId == null) return;
    _savedJobIds.remove(jobId);
    await _jobService.removeSavedJobForUser(_userId!, jobId);
    notifyListeners();
  }

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);
}
