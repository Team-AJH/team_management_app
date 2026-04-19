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

enum TrackerType {
  monthlyDues,
  customExpense;

  String get value => name;

  static TrackerType fromString(String raw) {
    switch (raw) {
      case 'monthlyDues':
        return TrackerType.monthlyDues;
      case 'customExpense':
        return TrackerType.customExpense;
      default:
        return TrackerType.monthlyDues;
    }
  }
}

class PaymentTracker {
  /// The unique document ID for this tracker in Firestore
  final String docId;
  /// The ID of the user responsible for this payment
  final String userUid;
  /// The ID of the group this payment belongs to
  final String groupId;
  /// The current status of the payment
  final PaymentStatus paymentStatus;
  /// When the payment was marked as verified
  final DateTime? paymentDate;
  /// The type of payment (monthly dues vs a one-off expense linked to a Transaction)
  final TrackerType type;
  /// For monthly dues, e.g. "2026-04". For customExpenses, this could be null or store the created month.
  final String billingMonth;
  /// If type == customExpense, the ID of the TransactionModel this fulfills
  final String? transactionId;
  /// The amount due for this specific payment
  final double amountDue;

  const PaymentTracker({
    required this.docId,
    required this.userUid,
    required this.groupId,
    required this.paymentStatus,
    required this.paymentDate,
    required this.type,
    required this.billingMonth,
    this.transactionId,
    this.amountDue = 0.0,
  });

  PaymentTracker copyWith({
    String? docId,
    String? userUid,
    String? groupId,
    PaymentStatus? paymentStatus,
    DateTime? paymentDate,
    bool clearPaymentDate = false,
    TrackerType? type,
    String? billingMonth,
    String? transactionId,
    double? amountDue,
  }) {
    return PaymentTracker(
      docId: docId ?? this.docId,
      userUid: userUid ?? this.userUid,
      groupId: groupId ?? this.groupId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: clearPaymentDate ? null : (paymentDate ?? this.paymentDate),
      type: type ?? this.type,
      billingMonth: billingMonth ?? this.billingMonth,
      transactionId: transactionId ?? this.transactionId,
      amountDue: amountDue ?? this.amountDue,
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
      type: TrackerType.fromString((data['type'] ?? 'monthlyDues') as String),
      billingMonth: (data['billingMonth'] ?? '') as String,
      transactionId: data['transactionId'] as String?,
      amountDue: (data['amountDue'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'groupId': groupId,
      'paymentStatus': paymentStatus.value,
      'paymentDate': paymentDate == null ? null : Timestamp.fromDate(paymentDate!),
      'type': type.value,
      'billingMonth': billingMonth,
      'transactionId': transactionId,
      'amountDue': amountDue,
    };
  }

  static String buildTrackerId({
    required String userUid,
    required String groupId,
    required String billingMonth,
    String? transactionId,
  }) {
    if (transactionId != null && transactionId.isNotEmpty) {
      return '${userUid}_${groupId}_transaction_$transactionId';
    }
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