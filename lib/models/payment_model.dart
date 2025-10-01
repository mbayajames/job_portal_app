import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String phoneNumber;
  final String amount;
  final String status;
  final String transactionDesc;
  final DateTime createdAt;
  final String? subscriptionStatus;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionExpiryDate;
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

  factory PaymentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return PaymentModel(
      id: map['merchantRequestId'] ?? map['mpesaReceiptNumber'] ?? docId ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '0',
      status: map['status']?.toString() ?? 'PENDING',
      transactionDesc: map['transactionDesc']?.toString() ?? 'No description',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      subscriptionStatus: map['subscriptionStatus']?.toString(),
      subscriptionStartDate: map['subscriptionStartDate'] is Timestamp
          ? (map['subscriptionStartDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['subscriptionStartDate']?.toString() ?? ''),
      subscriptionExpiryDate: map['subscriptionExpiryDate'] is Timestamp
          ? (map['subscriptionExpiryDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['subscriptionExpiryDate']?.toString() ?? ''),
      mpesaReceiptNumber: map['mpesaReceiptNumber']?.toString(),
      checkoutRequestId: map['checkoutRequestId']?.toString(),
      merchantRequestId: map['merchantRequestId']?.toString(),
      resultCode: int.tryParse(map['resultCode']?.toString() ?? ''),
    );
  }
}