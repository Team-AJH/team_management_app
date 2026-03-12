import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Placeholder function for retrieving the roster
  Stream<QuerySnapshot> getRoster() {
    return _firestore.collection('rosters').snapshots();
  }

  // Placeholder function for adding to the roster
  Future<void> addPlayer(String teamId, Map<String, dynamic> playerData) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('rosters')
        .add(playerData);
  }

  // Placeholder function for retrieving expenses
  Stream<QuerySnapshot> getExpenses() {
    return _firestore.collection('expenses').snapshots();
  }

  // Placeholder function for recording a payment
  Future<void> recordPayment(String teamId, Map<String, dynamic> paymentData) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('expenses')
        .add(paymentData);
  }

  // Placeholder function to retrieve notifications
  Stream<QuerySnapshot> getNotifications() {
    return _firestore.collection('notifications').orderBy('timestamp', descending: true).snapshots();
  }
}
