import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid; // Firebase UID
  final String email; // User's email
  final String displayName; // User's display name
  final String status; // User's status (e.g., "active", "injured", "vacation")
  final DateTime createdAt; // Account creation date

  // Constructor
  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.status,
    required this.createdAt,
  });

  // Convert AppUser to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create an AppUser from a Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Create an AppUser from a Firestore document snapshot
  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppUser.fromMap(data);
  }
}