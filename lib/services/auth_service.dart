import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -----------------------
  // REGISTER
  // -----------------------
  Future<User?> registerWithEmailAndPassword(
      String fullName, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // save extra user info to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      throw Exception("Register failed: $e");
    }
  }

  // Alias for register (used in register_screen.dart)
  Future<User?> register(String fullName, String email, String password) {
    return registerWithEmailAndPassword(fullName, email, password);
  }

  // -----------------------
  // LOGIN
  // -----------------------
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
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

  // Alias for login (used in login_screen.dart)
  Future<User?> login(String email, String password) {
    return signInWithEmailAndPassword(email, password);
  }

  // -----------------------
  // RESET PASSWORD
  // -----------------------
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Password reset failed: $e");
    }
  }

  // -----------------------
  // LOGOUT
  // -----------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // -----------------------
  // USER STREAM
  // -----------------------
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}
