import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ChatMessage.fromMap(data);
  }

  void validate() {
    if (groupId.trim().isEmpty) {
      throw Exception('Group ID is required.');
    }

    if (senderId.trim().isEmpty) {
      throw Exception('Sender ID is required.');
    }

   if (senderName.trim().isEmpty) {
      throw Exception('Sender name is required.');
    }

   if (message.trim().isEmpty) {
     throw Exception('Message cannot be empty.');
    }

   if (message.length > 500) {
     throw Exception('Message cannot exceed 500 characters.');
    }

    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty.');
    }
  }
}