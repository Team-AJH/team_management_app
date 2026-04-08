import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String groupId;
  final String title;
  final String content;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.groupId,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'content': content,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Announcement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return Announcement.fromMap(data);
  }

  void validate() {
    if (title.trim().isEmpty) {
     throw Exception('Announcement title cannot be empty.');
    }

    if (content.trim().isEmpty) {
      throw Exception('Announcement content cannot be empty.');
    }

    if (title.length > 100) {
      throw Exception('Title cannot exceed 100 characters.');
    }

    if (content.length > 1000) {
      throw Exception('Content cannot exceed 1000 characters.');
    }

    if (groupId.trim().isEmpty) {
      throw Exception('Group ID is required.');
    }

    if (createdBy.trim().isEmpty) {
      throw Exception('Creator ID is required.');
    }
  }
}