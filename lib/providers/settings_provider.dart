import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  String subscriptionPlan = "Free"; // Default
  bool twoFactorEnabled = false;

  // Getters
  bool get emailNotifications => _emailNotifications;
  bool get pushNotifications => _pushNotifications;
  bool get smsNotifications => _smsNotifications;

  // Setters with notifyListeners
  set emailNotifications(bool value) {
    _emailNotifications = value;
    notifyListeners();
  }

  set pushNotifications(bool value) {
    _pushNotifications = value;
    notifyListeners();
  }

  set smsNotifications(bool value) {
    _smsNotifications = value;
    notifyListeners();
  }

  bool isLoading = false;
  String? errorMessage;

  /// Load settings from Firestore (users collection)
  Future<void> loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection("users").doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final notif = data["notifications"] ?? {};

        _emailNotifications = notif["email"] ?? true;
        _pushNotifications = notif["push"] ?? true;
        _smsNotifications = notif["sms"] ?? false;
        subscriptionPlan = data["subscriptionPlan"] ?? "Free";
        twoFactorEnabled = data["twoFactorEnabled"] ?? false;
      }
    } catch (e) {
      errorMessage = "Failed to load settings: $e";
    }
    notifyListeners();
  }

  /// Update notification settings
  Future<void> updateNotifications({
    bool? email,
    bool? push,
    bool? sms,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection("users").doc(user.uid).set({
        "notifications": {
          "email": email ?? emailNotifications,
          "push": push ?? pushNotifications,
          "sms": sms ?? smsNotifications,
        }
      }, SetOptions(merge: true));

      // Update local state
      if (email != null) _emailNotifications = email;
      if (push != null) _pushNotifications = push;
      if (sms != null) _smsNotifications = sms;
    } catch (e) {
      errorMessage = "Failed to update notifications: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Change subscription plan
  Future<void> changeSubscriptionPlan(String newPlan) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("users").doc(user.uid).set(
        {"subscriptionPlan": newPlan},
        SetOptions(merge: true),
      );
      subscriptionPlan = newPlan;
    } catch (e) {
      errorMessage = "Failed to change subscription plan: $e";
    }
    notifyListeners();
  }

  /// Enable or disable 2FA
  Future<void> toggleTwoFactor(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("users").doc(user.uid).set(
        {"twoFactorEnabled": enabled},
        SetOptions(merge: true),
      );
      twoFactorEnabled = enabled;
    } catch (e) {
      errorMessage = "Failed to update two-factor auth: $e";
    }
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("users").doc(user.uid).set({
        "notifications": {
          "email": true,
          "sms": false,
          "push": true,
        },
        "subscriptionPlan": "Free",
        "twoFactorEnabled": false,
      }, SetOptions(merge: true));

      _emailNotifications = true;
      _pushNotifications = true;
      _smsNotifications = false;
      subscriptionPlan = "Free";
      twoFactorEnabled = false;
    } catch (e) {
      errorMessage = "Failed to reset settings: $e";
    }
    notifyListeners();
  }
}
