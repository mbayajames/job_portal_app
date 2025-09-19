import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  String? role;
  bool isLoading = false;
  String? errorMessage;

  // Valid roles
  static const List<String> _validRoles = ['seeker', 'employer', 'admin'];

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get currentUserData => _userData;
  bool get isSeeker => role == 'seeker';
  bool get isEmployer => role == 'employer';
  bool get isAdmin => role == 'admin';

  AuthProvider() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (_user != null) {
        await _fetchUserData(_user!.uid);
      } else {
        _userData = null;
        role = null;
      }
      notifyListeners();
    });
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = doc.data();
        role = _userData?['role']?.toLowerCase();
        if (!_validRoles.contains(role)) {
          role = 'seeker'; // Default to seeker if role is invalid
          errorMessage = 'Invalid user role. Defaulted to seeker.';
        }
      } else {
        errorMessage = 'User data not found.';
      }
    } catch (e) {
      _userData = null;
      role = null;
      errorMessage = 'Failed to fetch user data: $e';
    }
    notifyListeners();
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      errorMessage = 'Email and password cannot be empty.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _user = credential.user;

      if (!(_user?.emailVerified ?? false)) {
        await _auth.signOut();
        errorMessage = 'Please verify your email. Check your inbox or spam folder.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      await _fetchUserData(_user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found for this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed. Please try again.';
      }
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'An unexpected error occurred: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up
  Future<bool> signUp(
      String email, String password, Map<String, dynamic> userData) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      errorMessage = 'Email and password cannot be empty.';
      notifyListeners();
      return false;
    }

    final roleInput = userData['role']?.toString().toLowerCase();
    if (!_validRoles.contains(roleInput)) {
      errorMessage = 'Invalid role. Must be one of: ${_validRoles.join(", ")}';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _user = credential.user;
      final uid = _user!.uid;

      // Save user info in Firestore
      await _firestore.collection('users').doc(uid).set({
        ...userData,
        'role': roleInput,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email verification
      await _user!.sendEmailVerification();

      await _fetchUserData(uid);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'weak-password':
          errorMessage = 'Password must be at least 6 characters.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        default:
          errorMessage = e.message ?? 'Sign-up failed. Please try again.';
      }
      return false;
    } catch (e) {
      errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userData = null;
    role = null;
    errorMessage = null;
    notifyListeners();
  }

  // Send password reset email
  Future<bool> sendPasswordReset({required String email}) async {
    if (email.trim().isEmpty) {
      errorMessage = 'Email cannot be empty.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send password reset email.';
      }
      return false;
    } catch (e) {
      errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) {
      errorMessage = 'No user is signed in.';
      notifyListeners();
      return false;
    }

    if (updates.containsKey('role') && !_validRoles.contains(updates['role']?.toString().toLowerCase())) {
      errorMessage = 'Invalid role. Must be one of: ${_validRoles.join(", ")}';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _fetchUserData(_user!.uid);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update profile: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    if (_user == null) return false;
    await _user!.reload();
    _user = _auth.currentUser;
    return _user?.emailVerified ?? false;
  }
}