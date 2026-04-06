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
    // 1. Corregido: Tu colección principal se llama 'group', no 'groups'
    final groupSnapshot = await _db.collection('group').doc(groupId).get();
    
    if (!groupSnapshot.exists || groupSnapshot.data() == null) return;
    
    // 2. Corregido: En Firebase, 'members' se guarda como una lista de Mapas, no de Strings
    final List<dynamic> usersList = groupSnapshot.data()!['members'] ?? [];
    
    for (var user in usersList) {
      // Extraemos el sub-campo 'uid' del mapa del usuario. 
      // (Si tu AppUser.toMap usa 'id' en lugar de 'uid', cámbialo aquí)
      final String userUid = user['uid'] ?? ''; 
      
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
