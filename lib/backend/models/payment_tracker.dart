//FINISHED
enum PaymentStatus { pending, verified, rejected }

class PaymentTracker {
  final String docId;
  final String userUid;
  final String groupId;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final String billingMonth;

  PaymentTracker({
    required this.docId,
    required this.userUid,
    required this.groupId,
    required this.paymentStatus,
    this.paymentDate,
    required this.billingMonth,
  });

  //-------------------------------------------------CONVERTER FUNCTIONS----------------------------------------------------

  // convert from firestore document to PaymentTracker object
  factory PaymentTracker.fromMap(Map<String, dynamic> data, String docId) {
    return PaymentTracker(
      docId: docId,
      userUid: data['userUid'] ?? '',
      groupId: data['groupId'] ?? '',
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentDate: data['paymentDate'] != null
          ? (data['paymentDate'] as dynamic).toDate()
          : null,
      billingMonth: data['billingMonth'] ?? '',
    );
  }
  // convert object to firestore document
  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'groupId': groupId,
      'paymentStatus': paymentStatus.name,
      'paymentDate': paymentDate,
      'billingMonth': billingMonth,
    };
  }

  //build custom tracker id
  static String buildTrackerId({
    required String userUid,
    required String groupId,
    required String billingMonth,
  }) {
    return '$userUid-$groupId-$billingMonth';
  }

  //-------------------------------------------------MONTH KEY GENERATOR FUNCTIONS----------------------------------------------------

  // generates key for current month
  static String getMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  //generates key for upcoming month (i think this is the general scenario)
  static String getNextMonthKey() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    return '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}';
  }

  // generates key for a custom date
  static String getCustomMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}

/* to generate the dateKey to find 
String getCurrentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
*/





// diseno final final o con el payment status mutable y poder cambiarlo. Para el service hacer solo 
// de manera general, update, subir, crear, borrar, etc, o hacer metodos especificos tipo
// updateToVerified, updateToPending, updateToRejected, etc.