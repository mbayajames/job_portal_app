import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleGuard extends StatelessWidget {
  final String requiredRole;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  Future<bool> _hasAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    final role = doc.data()?["role"];

    return role == requiredRole;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child; // ✅ Access granted
        } else {
          return const Scaffold(
            body: Center(
              child: Text("🚫 Access Denied"),
            ),
          );
        }
      },
    );
  }
}
