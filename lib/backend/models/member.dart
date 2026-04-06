import 'package:cloud_firestore/cloud_firestore.dart';

enum Role {
  admin,
  member,
  paymentManager,
}

class Member {
  final String userId;
  final String groupId;
  final Role role;
  final DateTime joinedAt;

  Member({
    required this.userId,
    required this.groupId,
    required this.role,
    required this.joinedAt,
  });

  // convert from firestore document to Member object
  factory Member.fromMap(Map<String, dynamic> data, String documentId) {
    return Member(
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      role: data['role'] != null
          ? Role.values.firstWhere(
              (e) => e.name == data['role'],
              orElse: () => Role.member,
            )
          : Role.member,
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // convert Member object to firestore document map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'groupId': groupId,
      'role': role.name,
      'joinedAt': joinedAt,
    };
  }
}
