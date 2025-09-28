// lib/providers/employer_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployerProfileProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _employerProfile;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get employerProfile => _employerProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load employer profile from Firestore
  Future<void> fetchEmployerProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('employers')
          .doc(user.uid)
          .get();

      _employerProfile = snapshot.data();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save or update a single profile field
  Future<void> updateField(String field, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('employers').doc(user.uid).set(
        {field: value},
        SetOptions(merge: true),
      );

      _employerProfile?[field] = value;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
