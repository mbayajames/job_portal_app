import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id; // Using merchantRequestId or mpesaReceiptNumber as ID
  final String phoneNumber;
  final String amount;
  final String status;
  final String transactionDesc; // Using checkoutRequestId or description
  final DateTime createdAt; // Using transactionDate
  final String? subscriptionStatus; // Derived from role or premiumExpiry
  final DateTime? subscriptionStartDate; // Derived from premiumUpdatedAt
  final DateTime? subscriptionExpiryDate; // Using premiumExpiry
  final String? mpesaReceiptNumber;
  final String? checkoutRequestId;
  final String? merchantRequestId;
  final int? resultCode;

  PaymentModel({
    required this.id,
    required this.phoneNumber,
    required this.amount,
    required this.status,
    required this.transactionDesc,
    required this.createdAt,
    this.subscriptionStatus,
    this.subscriptionStartDate,
    this.subscriptionExpiryDate,
    this.mpesaReceiptNumber,
    this.checkoutRequestId,
    this.merchantRequestId,
    this.resultCode,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'status': status,
      'transactionDesc': transactionDesc,
      'createdAt': Timestamp.fromDate(createdAt),
      if (subscriptionStatus != null) 'subscriptionStatus': subscriptionStatus,
      if (subscriptionStartDate != null) 'subscriptionStartDate': Timestamp.fromDate(subscriptionStartDate!),
      if (subscriptionExpiryDate != null) 'subscriptionExpiryDate': Timestamp.fromDate(subscriptionExpiryDate!),
      if (mpesaReceiptNumber != null) 'mpesaReceiptNumber': mpesaReceiptNumber,
      if (checkoutRequestId != null) 'checkoutRequestId': checkoutRequestId,
      if (merchantRequestId != null) 'merchantRequestId': merchantRequestId,
      if (resultCode != null) 'resultCode': resultCode,
    };
  }

  // Read from Firestore map (from lastPayment field in users collection)
  factory PaymentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return PaymentModel(
      id: map['merchantRequestId'] ?? map['mpesaReceiptNumber'] ?? docId ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '0',
      status: map['status'] ?? 'Pending',
      transactionDesc: map['checkoutRequestId'] ?? map['transactionDesc'] ?? 'No description',
      createdAt: map['transactionDate'] is Timestamp
          ? (map['transactionDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['transactionDate'] ?? '') ?? DateTime.now(),
      subscriptionStatus: map['subscriptionStatus'] ?? (map['role'] == 'premium' ? 'Active' : 'Inactive'),
      subscriptionStartDate: map['premiumUpdatedAt'] is Timestamp
          ? (map['premiumUpdatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['premiumUpdatedAt'] ?? ''),
      subscriptionExpiryDate: map['premiumExpiry'] is Timestamp
          ? (map['premiumExpiry'] as Timestamp).toDate()
          : DateTime.tryParse(map['premiumExpiry'] ?? ''),
      mpesaReceiptNumber: map['mpesaReceiptNumber'],
      checkoutRequestId: map['checkoutRequestId'],
      merchantRequestId: map['merchantRequestId'],
      resultCode: map['resultCode'],
    );
  }
}