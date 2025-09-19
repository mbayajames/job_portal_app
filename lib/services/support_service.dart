import 'package:cloud_firestore/cloud_firestore.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a support ticket
  Future<void> submitTicket(String userId, String subject, String message) async {
    try {
      await _firestore.collection('support_tickets').add({
        'userId': userId,
        'subject': subject,
        'message': message,
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit ticket: $e');
    }
  }

  // Fetch support tickets for user
  Stream<List<Map<String, dynamic>>> getTickets(String userId) => _firestore
      .collection('support_tickets')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {
            ...doc.data(),
            'id': doc.id,
          }).toList());
}