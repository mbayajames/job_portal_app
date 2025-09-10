import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  AuthProvider() {
    _auth.authStateChanges().listen((event) {
      user = event;
      notifyListeners();
    });
  }

  // Register
  Future<void> register(String fullName, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      user = userCredential.user;

      await _firestore.collection('users').doc(user!.uid).set({
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      Fluttertoast.showToast(msg: "Registration Successful");
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Error");
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Fluttertoast.showToast(msg: "Login Successful");
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Error");
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    Fluttertoast.showToast(msg: "Logged Out");
  }

  // Forgot Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(msg: "Password reset email sent");
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Error");
    }
  }
}
