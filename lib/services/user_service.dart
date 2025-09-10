import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  Future<void> saveUserProfile(String uid, String name, String role) async {
    await users.doc(uid).set({
      'name': name,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
