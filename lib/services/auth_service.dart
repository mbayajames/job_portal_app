import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Register user with role
  Future<User?> register(String email, String password, String name, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Save role in Firestore
        await _firestore.collection("users").doc(user.uid).set({
          "email": email,
          "name": name,
          "role": role,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        return doc["role"] as String?;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 🔹 Get current logged-in user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
