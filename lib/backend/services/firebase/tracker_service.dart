//FINISHED
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_management_app/backend/models/payment_tracker.dart';

class TrackerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _trackersCollection =>
      _db.collection('paymentTrackers');

  // Creates a new tracker document in the "trackers" collection.
  Future<void> createTrackerDocument(
    String uid,
    String groupId,
    String billingMonth,
  ) async {
    final trackerId = PaymentTracker.buildTrackerId(
      userUid: uid,
      groupId: groupId,
      billingMonth: billingMonth,
    );

    final PaymentTracker newTracker = PaymentTracker(
      docId: trackerId,
      userUid: uid,
      groupId: groupId,
      paymentStatus: PaymentStatus.pending,
      paymentDate: null,
      billingMonth: billingMonth,
    );

    await _trackersCollection.doc(trackerId).set(newTracker.toMap());
  }

  //---------------------------------------GENERIC USE FUNCTIONS--------------------------------------------------------------------

  //create function to retrieve tracker document using tracker id
  Future<PaymentTracker?> getTrackerDocument(String trackerId) async {
    final docSnapshot = await _trackersCollection.doc(trackerId).get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return PaymentTracker.fromMap(docSnapshot.data()!, docSnapshot.id);
    }

    return null;
  }

  // Updates an existing tracker's information.
  Future<void> updateTrackerDocument(
    String trackerId,
    Map<String, dynamic> dataToUpdate,
  ) async {
    await _trackersCollection.doc(trackerId).update(dataToUpdate);
  }

  // Deletes a tracker document.
  Future<void> deleteTrackerDocument(String trackerId) async {
    await _trackersCollection.doc(trackerId).delete();
  }
  //---------------------------------------SPECIFIC USE FUNCTIONS--------------------------------------------------------------------

  // update payment status for a single user
  Future<void> updatePaymentStatus(
    String trackerId,
    PaymentStatus status,
  ) async {
    switch (status) {
      case PaymentStatus.pending:
        await _trackersCollection.doc(trackerId).update({
          'paymentStatus': status.name,
          'paymentDate': null,
        });
        break;
      case PaymentStatus.verified:
        await _trackersCollection.doc(trackerId).update({
          'paymentStatus': status.name,
          'paymentDate': DateTime.now(),
        });
        break;
      case PaymentStatus.rejected:
        await _trackersCollection.doc(trackerId).update({
          'paymentStatus': status.name,
          'paymentDate': null,
        });
        break;
    }
  }

  // function to create trackers for all users in a group for a specific month
  Future<void> createTrackersForGroup(String groupId, String billingMonth) async {
    // Fetch all member documents from the 'members' subcollection of the group
    final membersSnapshot = await _db
        .collection('group')
        .doc(groupId)
        .collection('members')
        .get();

    if (membersSnapshot.docs.isEmpty) return;
    
    // Iterate through the subcollection documents. 
    // Since the document IDs in the members subcollection are the UIDs, we use doc.id directly!
    for (var doc in membersSnapshot.docs) {
      final String userUid = doc.id;
      
      if (userUid.isNotEmpty) {
        await createTrackerDocument(userUid, groupId, billingMonth);
      }
    }
  }

  // function that returns a list of payment trackers based on specific group and billing month
  // use the month key generator functions to generate the billing month key
  Future<List<PaymentTracker>> getTrackersByGroupAndMonth(
    String groupId,
    String billingMonth,
  ) async {
    final querySnapshot = await _trackersCollection
        .where('groupId', isEqualTo: groupId)
        .where('billingMonth', isEqualTo: billingMonth)
        .get();

    return querySnapshot.docs
        .map((doc) => PaymentTracker.fromMap(doc.data()!, doc.id))
        .toList();
  }
}
