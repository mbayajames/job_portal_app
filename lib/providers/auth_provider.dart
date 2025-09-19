import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? role;

  // Register user and save role in Firestore
  Future<void> register(String email, String password, String userRole) async {
    isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': userRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      role = userRole;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Login and fetch role from Firestore
  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        role = null; // User must complete registration
      } else {
        role = doc.data()?['role'];
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    role = null;
    notifyListeners();
  }

  // Send password reset
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser => _auth.currentUser;
}
