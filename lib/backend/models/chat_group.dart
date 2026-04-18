import 'package:cloud_firestore/cloud_firestore.dart';

class ChatGroup {
  final String id;
  final String name;
  final List<String> memberIds;
  final DateTime createdAt;

  ChatGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatGroup.fromMap(Map<String, dynamic> map, String id) {
    return ChatGroup(
      id: id,
      name: map['name'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
