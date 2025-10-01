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
    String type = 'general',
    Map<String, dynamic>? metadata,
  }) async {
    await _firestore.collection('notifications').add({
      'employerId': employerId,
      'title': title,
      'message': message,
      'type': type,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
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
    String type = 'general',
    Map<String, dynamic>? metadata,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
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

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  /// Convenience method: notify employer when a user applies to a job
  Future<void> notifyEmployerOnApplication({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String applicantName,
    required String applicantId,
  }) async {
    await sendNotificationToEmployer(
      employerId: employerId,
      title: 'New Application Received',
      message: '$applicantName has applied for your job: $jobTitle',
      type: 'application',
    );
  }

  /// Notify employer when payment is received
  Future<void> notifyEmployerPaymentReceived({
    required String employerId,
    required String amount,
    required String transactionId,
  }) async {
    await sendNotificationToEmployer(
      employerId: employerId,
      title: 'Payment Received',
      message: 'You have received a payment of $amount. Transaction ID: $transactionId',
      type: 'payment',
    );
  }

  /// Notify employer when job is saved
  Future<void> notifyEmployerJobSaved({
    required String employerId,
    required String jobId,
    required String jobTitle,
    required String seekerName,
  }) async {
    await sendNotificationToEmployer(
      employerId: employerId,
      title: 'Job Saved',
      message: '$seekerName has saved your job: $jobTitle',
      type: 'job_saved',
    );
  }

  /// Notify user that their application was submitted
  Future<void> notifySeekerApplicationSubmitted({
    required String userId,
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Application Submitted',
      message: 'Your application for $jobTitle at $companyName has been submitted successfully.',
      type: 'application',
    );
  }

  /// Notify user they are hired
  Future<void> notifySeekerHired({
    required String userId,
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Congratulations! You\'re Hired',
      message: 'You have been hired for the position of $jobTitle at $companyName.',
      type: 'hired',
    );
  }

  /// Notify user about application status update
  Future<void> notifySeekerApplicationStatusUpdate({
    required String userId,
    required String jobTitle,
    required String status,
    required String jobId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Application Status Update',
      message: 'Your application status for $jobTitle has been updated to: $status.',
      type: 'status_update',
    );
  }

  /// Notify user about interview schedule
  Future<void> notifySeekerInterviewScheduled({
    required String userId,
    required String jobTitle,
    required String companyName,
    required DateTime interviewDate,
    required String location,
    required String jobId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Interview Scheduled',
      message: 'Your interview for $jobTitle at $companyName is scheduled on ${interviewDate.toString()} at $location.',
      type: 'interview',
    );
  }

  /// Notify user about new job match
  Future<void> notifySeekerNewJobMatch({
    required String userId,
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'New Job Match',
      message: 'You have a new job match: $jobTitle at $companyName.',
      type: 'job_match',
    );
  }

  /// Notify user about profile update
  Future<void> notifySeekerProfileUpdated({
    required String userId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Profile Updated',
      message: 'Your profile has been updated successfully.',
      type: 'profile',
    );
  }

  /// Notify user about settings update
  Future<void> notifySeekerSettingsUpdated({
    required String userId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Settings Updated',
      message: 'Your settings have been updated successfully.',
      type: 'settings',
    );
  }

  /// Notify user when saved job is closed
  Future<void> notifySeekerSavedJobClosed({
    required String userId,
    required String jobTitle,
    required String companyName,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Saved Job Closed',
      message: 'The job $jobTitle at $companyName that you saved has been closed.',
      type: 'job_closed',
    );
  }
}
