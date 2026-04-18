import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/group_member.dart';
import '../services/chat_service.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  String? currentUserId;

  ChatRepository({this.currentUserId});

  // ── Group messaging ──────────────────────────────────────────────────────

  Future<void> sendMessage({
    required GroupMember member,
    required String groupId,
    required String text,
  }) async {
    final docRef = _firestore.collection('groups').doc(groupId).collection('messages').doc();
    final message = _chatService.createMessage(
      member: member,
      id: docRef.id,
      groupId: groupId,
      message: text,
      createdAt: DateTime.now(),
    );
    await docRef.set(message.toMap());
  }

  Stream<List<ChatMessage>> getMessagesStream({required String groupId}) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data())).toList());
  }

  // ── Direct messaging ─────────────────────────────────────────────────────

  /// Deterministic thread ID — always the same for two users regardless of who opens first.
  static String dmThreadId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> sendDirectMessage({
    required String fromUid,
    required String fromName,
    required String toUid,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final threadId = dmThreadId(fromUid, toUid);
    final messagesRef = _firestore
        .collection('directMessages')
        .doc(threadId)
        .collection('messages');

    // Ensure the thread metadata doc exists so we can query it later
    await _firestore.collection('directMessages').doc(threadId).set({
      'participants': [fromUid, toUid],
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': text.trim(),
    }, SetOptions(merge: true));

    final docRef = messagesRef.doc();
    await docRef.set({
      'id': docRef.id,
      'groupId': threadId,
      'senderId': fromUid,
      'senderName': fromName,
      'message': text.trim(),
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<ChatMessage>> getDirectMessagesStream({
    required String fromUid,
    required String toUid,
  }) {
    final threadId = dmThreadId(fromUid, toUid);
    return _firestore
        .collection('directMessages')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data())).toList());
  }

  /// Returns threads involving [uid] — used for the DM list.
  Stream<List<Map<String, dynamic>>> getDmThreads(String uid) {
    return _firestore
        .collection('directMessages')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'threadId': doc.id,
                ...data,
              };
            }).toList());
  }
}

