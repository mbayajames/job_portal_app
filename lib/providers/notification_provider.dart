import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  Stream<List<Map<String, dynamic>>> notificationsStream = Stream.value([]);
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool isLoading = false;

  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get notifications => _notifications;

  NotificationProvider() {
    // Initialize with empty stream, set userId later
  }

  void setUserId(String userId) {
    notificationsStream = _notificationService.getNotificationsStream(userId);
    _notificationService.getUnreadCountStream(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
    notificationsStream.listen((data) {
      _notifications = data;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    // Implement mark all as read
    notifyListeners();
  }
}