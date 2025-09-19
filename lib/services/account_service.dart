import 'package:cloud_firestore/cloud_firestore.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user preferences
  Future<void> savePreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save preferences: $e');
    }
  }

  // Fetch user preferences
  Future<Map<String, dynamic>?> getPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['preferences'] as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to fetch preferences: $e');
    }
  }
}