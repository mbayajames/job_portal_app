import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register new user
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception("Registration failed: $e");
    }
  }

  // Login existing user
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  // 🔹 Get current user ID
  String? currentUserId() {
    return _auth.currentUser?.uid;
  }

  // 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 🔹 Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // 🔹 Get current user object
  User? get currentUser {
    return _auth.currentUser;
  }
}
