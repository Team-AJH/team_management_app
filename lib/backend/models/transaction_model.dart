import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final DateTime date;
  final bool isCollection;
  final String? payerPayee;
  final String? paymentLink;

  TransactionModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.date,
    required this.isCollection,
    this.payerPayee,
    this.paymentLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'isCollection': isCollection,
      'payerPayee': payerPayee,
      'paymentLink': paymentLink,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TransactionModel(
      id: documentId,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      isCollection: map['isCollection'] ?? true,
      payerPayee: map['payerPayee'],
      paymentLink: map['paymentLink'],
    );
  }
}
