import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  /// 🔹 Update notification preferences
  Future<void> updateNotificationPreferences(String uid, Map<String, dynamic> prefs) async {
    await users.doc(uid).update({'notifications': prefs});
  }

  /// 🔹 Update subscription plan
  Future<void> updateSubscriptionPlan(String uid, String plan) async {
    await users.doc(uid).update({'subscriptionPlan': plan});
  }

  /// 🔹 Enable/Disable 2FA
  Future<void> updateTwoFactorAuth(String uid, bool enabled) async {
    await users.doc(uid).update({'twoFactorEnabled': enabled});
  }
}
