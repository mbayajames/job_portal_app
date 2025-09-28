import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state
  bool _isLoggedIn = false;
  User? _currentUser;
  UserModel? _userData;
  bool _isLoading = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  UserModel? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get userId => _currentUser?.uid;

  // Initialize auth state
  Future<void> initialize() async {
    try {
      await Preferences.init();
      _isLoading = true;
      notifyListeners();

      // Check if user is already logged in with Firebase
      _currentUser = _auth.currentUser;
      _isLoggedIn = _currentUser != null;

      if (_isLoggedIn && _currentUser != null) {
        // Load user data from Firestore
        await _loadUserData(_currentUser!.uid);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to initialize auth: $e');
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = userCredential.user;
      _isLoggedIn = true;

      if (_currentUser != null) {
        await _loadUserData(_currentUser!.uid);
        await _saveAuthState();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _handleAuthError(e);
    }
  }

  // Sign up with email, password, and user data
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role, // 'applicant' or 'employer'
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = userCredential.user;

      if (_currentUser != null) {
        // Update display name
        await _currentUser!.updateDisplayName(fullName);

        // Create user document in Firestore
        final userModel = UserModel(
          id: _currentUser!.uid,
          email: email,
          fullName: fullName,
          role: role,
          phone: phone,
          profileImage: null,
          resumeUrl: null,
          education: [],
          experience: [],
          skills: [],
          preferences: CareerPreferences(
            jobType: 'Full-time',
            preferredLocation: '',
            minSalary: 0,
            preferredIndustries: [],
            experienceLevel: 'Mid-level',
          ),
        );

        await _firestore.collection('users').doc(_currentUser!.uid).set({
          ...userModel.toMap(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _userData = userModel;
        _isLoggedIn = true;
        await _saveAuthState();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();
      await _clearAuthState();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to sign out: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(updatedUser.id).update({
        ...updatedUser.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _userData = updatedUser;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to update profile: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      if (_currentUser != null) {
        await _currentUser!.verifyBeforeUpdateEmail(newEmail);

        // Update in Firestore
        if (_userData != null) {
          final updatedUser = _userData!.copyWith(email: newEmail);
          await updateUserProfile(updatedUser);
        }
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      if (_currentUser != null) {
        await _currentUser!.updatePassword(newPassword);
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (_currentUser != null) {
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(_currentUser!.uid).delete();
        
        // Delete user account
        await _currentUser!.delete();
        await _clearAuthState();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        _userData = UserModel.fromMap(doc.data()!);
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }

  // Save auth state to preferences
  Future<void> _saveAuthState() async {
    await Preferences.setBool('isLoggedIn', true);
    await Preferences.setString('userId', _currentUser!.uid);
    await Preferences.setString('userEmail', _currentUser!.email ?? '');
  }

  // Clear auth state from preferences
  Future<void> _clearAuthState() async {
    _isLoggedIn = false;
    _currentUser = null;
    _userData = null;

    await Preferences.clear();
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'The password is incorrect.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'An unexpected error occurred. Please try again.';
      }
    }
    return error.toString();
  }

  // Listen to auth state changes
  void setupAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _isLoggedIn = false;
        _currentUser = null;
        _userData = null;
      } else {
        _isLoggedIn = true;
        _currentUser = user;
        await _loadUserData(user.uid);
      }
      notifyListeners();
    });
  }

  // Check if user has specific role
  Future<bool> hasRole(String role) async {
    if (_userData == null || _currentUser == null) return false;

    final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
    return doc.data()?['role'] == role;
  }

  // Get user role
  Future<String?> getUserRole() async {
    if (_currentUser == null) return null;
    
    final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
    return doc.data()?['role'] as String?;
  }
}