import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get stream of notifications for an employer
  Stream<List<NotificationModel>> getEmployerNotificationsStream(String employerId) {
    return _firestore
        .collection('notifications')
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of unread notification count for employer
  Stream<int> getEmployerUnreadCountStream(String employerId) {
    return _firestore
        .collection('notifications')
        .where('employerId', isEqualTo: employerId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all notifications as read for employer
  Future<void> markAllAsRead(String employerId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('employerId', isEqualTo: employerId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  /// Send a notification to an employer
  Future<void> sendNotificationToEmployer({
    required String employerId,
    required String title,
    required String message,
  }) async {
    await _firestore.collection('notifications').add({
      'employerId': employerId,
      'title': title,
      'message': message,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get stream of notifications for a user
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of unread notification count for user
  Stream<int> getUserUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Send a notification to a user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsReadForUser(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  /// Convenience method: notify employer when a user applies to a job
  Future<void> notifyEmployerOnApplication({
    required String employerId,
    required String jobTitle,
    required String applicantName,
  }) async {
    await sendNotificationToEmployer(
      employerId: employerId,
      title: 'New Application Received',
      message: '$applicantName has applied for your job: $jobTitle',
    );
  }
}
