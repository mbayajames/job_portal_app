import 'package:cloud_firestore/cloud_firestore.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a support ticket
  Future<void> createTicket(Map<String, dynamic> ticketData) async {
    final docRef = _firestore.collection('support_tickets').doc();
    await docRef.set({
      ...ticketData,
      'status': 'open', // open/closed
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get tickets for a user
  Stream<List<Map<String, dynamic>>> getTicketsForUser(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Update ticket status
  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
