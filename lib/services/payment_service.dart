import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch payment history for user
  Stream<List<Map<String, dynamic>>> getPaymentHistory(String userId) => _firestore
      .collection('payments')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {
            ...doc.data(),
            'id': doc.id,
          }).toList());

  // Add a payment record (for testing or premium features)
  Future<void> addPayment(String userId, Map<String, dynamic> paymentData) async {
    try {
      await _firestore.collection('payments').add({
        ...paymentData,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add payment: $e');
    }
  }
}