import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserData {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the 'users' collection in Firestore
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Create a new user document in Firestore using uid as the document ID
  Future<void> createUser(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  // Retrieve user data by uid
  Future<AppUser?> getUserById(String uid) async {
    final doc = await _usersCollection.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AppUser.fromFirestore(doc);
  }

  // Update user data in Firestore
  Future<void> updateUser(AppUser user) async {
    await _usersCollection.doc(user.uid).update(user.toMap());
  }

  // Update user status (e.g., "active", "injured", "vacation")
  Future<void> updateUserStatus(String uid, String status) async {
    await _usersCollection.doc(uid).update({'status': status});
  }
}