//FINISHED
import 'package:cloud_firestore/cloud_firestore.dart';
enum GlobalRole { globalAdmin,  user }

class AppUser {
  final String uid; // Firebase UID
  final String email; // User's email
  final String displayName; // User's display name
  final String status; // User's status (e.g., "active", "injured", "vacation")
  final DateTime createdAt; // Account creation date
  final GlobalRole? globalRole; // User's role (e.g., "admin", "paymentManager", "member")

  // Constructor
  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.status,
    required this.createdAt,
    required this.globalRole,
  });

  // Convert AppUser to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'globalRole': globalRole?.name,
    };
  }

  // Create an AppUser from a Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      globalRole: GlobalRole.values.firstWhere((e) => e.name == map['globalRole'], orElse: () => GlobalRole.user),
    );
  }

  // Create an AppUser from a Firestore document snapshot
  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppUser.fromMap(data, doc.id);
  }
}