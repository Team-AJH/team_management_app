import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_tracker.dart';

class TrackerService {
  final FirebaseFirestore _firestore;

  TrackerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _trackersCollection(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('paymentTrackers');

  Future<PaymentTracker> createTrackerDocument({
    required String uid,
    required String groupId,
    required String billingMonth,
    String? transactionId,
    double amountDue = 0.0,
    TrackerType type = TrackerType.monthlyDues,
  }) async {
    final trackerId = PaymentTracker.buildTrackerId(
      userUid: uid,
      groupId: groupId,
      billingMonth: billingMonth,
      transactionId: transactionId,
    );

    final tracker = PaymentTracker(
      docId: trackerId,
      userUid: uid,
      groupId: groupId,
      paymentStatus: PaymentStatus.pending,
      paymentDate: null,
      type: type,
      billingMonth: billingMonth,
      transactionId: transactionId,
      amountDue: amountDue,
    );

    await _trackersCollection(groupId).doc(trackerId).set(tracker.toMap());

    return tracker;
  }

  Future<PaymentTracker?> getTrackerDocument(String groupId, String trackerId) async {
    final doc = await _trackersCollection(groupId).doc(trackerId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return PaymentTracker.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateTrackerDocument({
    required String groupId,
    required String trackerId,
    required Map<String, dynamic> dataToUpdate,
  }) async {
    await _trackersCollection(groupId).doc(trackerId).update(dataToUpdate);
  }

  Future<void> deleteTrackerDocument({
    required String groupId,
    required String trackerId,
  }) async {
    await _trackersCollection(groupId).doc(trackerId).delete();
  }

  Future<void> updatePaymentStatus({
    required String groupId,
    required String trackerId,
    required PaymentStatus status,
  }) async {
    final updateData = <String, dynamic>{
      'paymentStatus': status.value,
      'paymentDate': status == PaymentStatus.verified
          ? FieldValue.serverTimestamp()
          : null,
    };

    await _trackersCollection(groupId).doc(trackerId).update(updateData);
  }

  Future<List<PaymentTracker>> getTrackersByGroupAndMonth({
    required String groupId,
    required String billingMonth,
  }) async {
    final snapshot = await _trackersCollection(groupId)
        .where('billingMonth', isEqualTo: billingMonth)
        .orderBy('userUid') // Can remove grouping where clause since it's subcollection
        .get();

    return snapshot.docs
        .map((doc) => PaymentTracker.fromMap(doc.data(), doc.id))
        .toList();
  }
  
  Future<List<PaymentTracker>> getTrackersForTransaction({
    required String groupId,
    required String transactionId,
  }) async {
    final snapshot = await _trackersCollection(groupId)
        .where('transactionId', isEqualTo: transactionId)
        .orderBy('userUid')
        .get();

    return snapshot.docs
        .map((doc) => PaymentTracker.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> createTrackersForGroupMembers({
    required List<String> memberUids,
    required String groupId,
    required String billingMonth,
    String? transactionId,
    double amountDue = 0.0,
    TrackerType type = TrackerType.monthlyDues,
  }) async {
    final batch = _firestore.batch();

    for (final uid in memberUids) {
      final trackerId = PaymentTracker.buildTrackerId(
        userUid: uid,
        groupId: groupId,
        billingMonth: billingMonth,
        transactionId: transactionId,
      );

      final tracker = PaymentTracker(
        docId: trackerId,
        userUid: uid,
        groupId: groupId,
        paymentStatus: PaymentStatus.pending,
        paymentDate: null,
        type: type,
        billingMonth: billingMonth,
        transactionId: transactionId,
        amountDue: amountDue,
      );

      batch.set(_trackersCollection(groupId).doc(trackerId), tracker.toMap());
    }

    await batch.commit();
  }
}