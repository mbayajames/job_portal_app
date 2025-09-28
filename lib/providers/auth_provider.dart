import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  String? _role;
  bool isLoading = false;
  String? errorMessage;

  static const List<String> _validRoles = ['seeker', 'employer', 'admin'];

  /// User-specific job filters
  Map<String, dynamic> _jobFilters = {};

  /// User-specific saved jobs (IDs)
  List<String> _savedJobIds = [];

  // Getters
  User? get user => _user;
  String? get uid => _user?.uid;
  String? get currentUserId => _user?.uid; // ✅ added
  Map<String, dynamic>? get currentUserData => _userData;
  String? get userRole => _role;
  bool get isLoggedIn => _user != null;
  bool get isSeeker => _role == 'seeker';
  bool get isEmployer => _role == 'employer';
  bool get isAdmin => _role == 'admin';
  Map<String, dynamic> get jobFilters => _jobFilters;
  List<String> get savedJobIds => _savedJobIds;

  AuthProvider() {
    _listenToAuthChanges();
  }

  /// Listen to Firebase auth state changes
  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((firebaseUser) async {
      _user = firebaseUser;
      if (_user != null) {
        await _fetchUserData(currentUserId!);
      } else {
        _userData = null;
        _role = null;
        _jobFilters = {};
        _savedJobIds = [];
      }
      notifyListeners();
    });
  }

  /// Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = doc.data();
        _role = _userData?['role']?.toString().toLowerCase();
        _jobFilters = _userData?['jobFilters'] ?? {};
        _savedJobIds = List<String>.from(_userData?['savedJobs'] ?? []);
        if (!_validRoles.contains(_role)) {
          _role = 'seeker';
          errorMessage = 'Invalid role found, defaulted to seeker.';
        }
      } else {
        _userData = null;
        _role = null;
        _jobFilters = {};
        _savedJobIds = [];
        errorMessage = 'User data not found.';
      }
    } catch (e) {
      _userData = null;
      _role = null;
      _jobFilters = {};
      _savedJobIds = [];
      errorMessage = 'Failed to fetch user data: $e';
    }
  }

  /// Sign in user
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
        await signOut();
        errorMessage = 'Please verify your email.';
        return false;
      }

      await _fetchUserData(currentUserId!);
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
          errorMessage = e.message ?? 'Login failed.';
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up user
  Future<bool> signUp(
      String email, String password, Map<String, dynamic> userData) async {
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
      final uid = currentUserId!;

      await _firestore.collection('users').doc(uid).set({
        ...userData,
        'role': roleInput,
        'twoFactorEnabled': false,
        'jobFilters': {},
        'savedJobs': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
          errorMessage = e.message ?? 'Sign-up failed.';
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Failed to send password reset email.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userData = null;
    _role = null;
    _jobFilters = {};
    _savedJobIds = [];
    errorMessage = null;
    notifyListeners();
  }

  /// Update profile and optionally job filters / saved jobs
  Future<bool> updateProfile(Map<String, dynamic> updates,
      {Map<String, dynamic>? filters, List<String>? savedJobs}) async {
    if (_user == null) {
      errorMessage = 'No user is signed in.';
      notifyListeners();
      return false;
    }

    if (updates.containsKey('role') &&
        !_validRoles.contains(updates['role']?.toString().toLowerCase())) {
      errorMessage = 'Invalid role. Must be one of: ${_validRoles.join(", ")}';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final dataToUpdate = {
        ...updates,
        if (filters != null) 'jobFilters': filters,
        if (savedJobs != null) 'savedJobs': savedJobs,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('users').doc(currentUserId!).update(dataToUpdate);
      await _fetchUserData(currentUserId!);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update profile: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Save job
  Future<void> saveJob(String jobId) async {
    if (_user == null) return;
    if (!_savedJobIds.contains(jobId)) {
      _savedJobIds.add(jobId);
      await _firestore.collection('users').doc(currentUserId!).update({
        'savedJobs': _savedJobIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    }
  }

  /// Remove saved job
  Future<void> removeSavedJob(String jobId) async {
    if (_user == null) return;
    _savedJobIds.remove(jobId);
    await _firestore.collection('users').doc(currentUserId!).update({
      'savedJobs': _savedJobIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);

  /// Set job filters
  void setJobFilters(Map<String, dynamic> filters) {
    _jobFilters = filters;
    notifyListeners();
  }

  void resetJobFilters() {
    _jobFilters = {};
    notifyListeners();
  }

  /// Check email verification
  Future<bool> checkEmailVerification() async {
    if (_user == null) return false;
    await _user!.reload();
    _user = _auth.currentUser;
    return _user?.emailVerified ?? false;
  }

  /// Load current user data
  Future<void> loadCurrentUser() async {
    if (_user != null) {
      await _fetchUserData(_user!.uid);
    }
  }
}
