import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_tracker.dart';
import '../services/tracker_service.dart';

class TrackerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TrackerService _trackerService = TrackerService();

  Future<void> createTracker({
    required String userUid,
    required String groupId,
    required String billingMonth,
  }) async {
    await _trackerService.createTrackerDocument(
      uid: userUid,
      groupId: groupId,
      billingMonth: billingMonth,
    );
  }

  Future<void> updatePaymentStatus({
    required String trackerId,
    required String actingUserUid,
    required bool isGroupAdmin,
    required PaymentStatus newStatus,
    required bool clearingDate,
  }) async {
    // In a real advanced logic we might enforce isGroupAdmin or actingUser restrictions
    await _trackerService.updatePaymentStatus(
      trackerId: trackerId,
      status: newStatus,
    );
  }

  Stream<List<PaymentTracker>> getTrackersForGroup(String groupId) {
    // Note that TrackerService uses collection 'paymentTrackers'
    return _firestore
        .collection('paymentTrackers')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentTracker.fromMap(doc.data(), doc.id))
            .toList());
  }
}
