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

  /// Send notifications
  Future<void> sendNotificationToEmployer({
    required String employerId,
    required String title,
    required String message,
  }) async {
    await _service.sendNotificationToEmployer(
      employerId: employerId,
      title: title,
      message: message,
    );
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _service.sendNotificationToUser(
      userId: userId,
      title: title,
      message: message,
    );
  }

  /// Notify employer on job application
  Future<void> notifyOnApplication({
    required String employerId,
    required String jobTitle,
    required String applicantName,
  }) async {
    await _service.notifyEmployerOnApplication(
      employerId: employerId,
      jobTitle: jobTitle,
      applicantName: applicantName,
    );
  }

  /// Notify user that their application was submitted
  Future<void> notifyApplicationSubmitted({
    required String jobTitle,
  }) async {
    if (_userId == null) return;
    await sendNotification(
      userId: _userId!,
      title: 'Application Submitted',
      message: 'Your application for "$jobTitle" has been successfully submitted!',
    );
  }

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
