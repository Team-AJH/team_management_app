import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_tracker.dart';

class TrackerService {
  final FirebaseFirestore _firestore;

  TrackerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _trackersCollection =>
      _firestore.collection('paymentTrackers');

  Future<PaymentTracker> createTrackerDocument({
    required String uid,
    required String groupId,
    required String billingMonth,
  }) async {
    final trackerId = PaymentTracker.buildTrackerId(
      userUid: uid,
      groupId: groupId,
      billingMonth: billingMonth,
    );

    final tracker = PaymentTracker(
      docId: trackerId,
      userUid: uid,
      groupId: groupId,
      paymentStatus: PaymentStatus.pending,
      paymentDate: null,
      billingMonth: billingMonth,
    );

    await _trackersCollection.doc(trackerId).set(tracker.toMap());

    return tracker;
  }

  Future<PaymentTracker?> getTrackerDocument(String trackerId) async {
    final doc = await _trackersCollection.doc(trackerId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return PaymentTracker.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateTrackerDocument({
    required String trackerId,
    required Map<String, dynamic> dataToUpdate,
  }) async {
    await _trackersCollection.doc(trackerId).update(dataToUpdate);
  }

  Future<void> deleteTrackerDocument(String trackerId) async {
    await _trackersCollection.doc(trackerId).delete();
  }

  Future<void> updatePaymentStatus({
    required String trackerId,
    required PaymentStatus status,
  }) async {
    final updateData = <String, dynamic>{
      'paymentStatus': status.value,
      'paymentDate': status == PaymentStatus.verified
          ? FieldValue.serverTimestamp()
          : null,
    };

    await _trackersCollection.doc(trackerId).update(updateData);
  }

  Future<List<PaymentTracker>> getTrackersByGroupAndMonth({
    required String groupId,
    required String billingMonth,
  }) async {
    final snapshot = await _trackersCollection
        .where('groupId', isEqualTo: groupId)
        .where('billingMonth', isEqualTo: billingMonth)
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
  }) async {
    final batch = _firestore.batch();

    for (final uid in memberUids) {
      final trackerId = PaymentTracker.buildTrackerId(
        userUid: uid,
        groupId: groupId,
        billingMonth: billingMonth,
      );

      final tracker = PaymentTracker(
        docId: trackerId,
        userUid: uid,
        groupId: groupId,
        paymentStatus: PaymentStatus.pending,
        paymentDate: null,
        billingMonth: billingMonth,
      );

      batch.set(_trackersCollection.doc(trackerId), tracker.toMap());
    }

    await batch.commit();
  }
}