import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending,
  verified,
  rejected;

  String get value => name;

  static PaymentStatus fromString(String raw) {
    switch (raw) {
      case 'pending':
        return PaymentStatus.pending;
      case 'verified':
        return PaymentStatus.verified;
      case 'rejected':
        return PaymentStatus.rejected;
      default:
        throw Exception('Invalid payment status: $raw');
    }
  }
}

class PaymentTracker {
  final String docId;
  final String userUid;
  final String groupId;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final String billingMonth;

  const PaymentTracker({
    required this.docId,
    required this.userUid,
    required this.groupId,
    required this.paymentStatus,
    required this.paymentDate,
    required this.billingMonth,
  });

  PaymentTracker copyWith({
    String? docId,
    String? userUid,
    String? groupId,
    PaymentStatus? paymentStatus,
    DateTime? paymentDate,
    bool clearPaymentDate = false,
    String? billingMonth,
  }) {
    return PaymentTracker(
      docId: docId ?? this.docId,
      userUid: userUid ?? this.userUid,
      groupId: groupId ?? this.groupId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: clearPaymentDate ? null : (paymentDate ?? this.paymentDate),
      billingMonth: billingMonth ?? this.billingMonth,
    );
  }

  factory PaymentTracker.fromMap(Map<String, dynamic> data, String docId) {
    final rawDate = data['paymentDate'];

    DateTime? parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return PaymentTracker(
      docId: docId,
      userUid: (data['userUid'] ?? '') as String,
      groupId: (data['groupId'] ?? '') as String,
      paymentStatus: PaymentStatus.fromString(
        (data['paymentStatus'] ?? 'pending') as String,
      ),
      paymentDate: parsedDate,
      billingMonth: (data['billingMonth'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'groupId': groupId,
      'paymentStatus': paymentStatus.value,
      'paymentDate': paymentDate == null ? null : Timestamp.fromDate(paymentDate!),
      'billingMonth': billingMonth,
    };
  }

  static String buildTrackerId({
    required String userUid,
    required String groupId,
    required String billingMonth,
  }) {
    return '${userUid}_${groupId}_$billingMonth';
  }

  static String getMonthKeyForDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  static String getCurrentMonthKey() {
    return getMonthKeyForDate(DateTime.now());
  }

  static String getNextMonthKey() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return getMonthKeyForDate(nextMonth);
  }
}