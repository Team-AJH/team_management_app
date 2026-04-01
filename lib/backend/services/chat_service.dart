import 'dart:async';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/chat_group.dart';

class ChatService {
  // --- MOCK DATA ---
  final String _currentUserId = 'user_1';
  
  final List<AppUser> _mockUsers = [
    AppUser(uid: 'user_1', email: 'me@example.com', displayName: 'My User (Me)', status: 'active', createdAt: DateTime.now()),
    AppUser(uid: 'user_2', email: 'alice@example.com', displayName: 'Alice Smith', status: 'active', createdAt: DateTime.now()),
    AppUser(uid: 'user_3', email: 'bob@example.com', displayName: 'Bob Johnson', status: 'injured', createdAt: DateTime.now()),
    AppUser(uid: 'user_4', email: 'charlie@example.com', displayName: 'Charlie Brown', status: 'active', createdAt: DateTime.now()),
  ];

  final List<ChatGroup> _mockGroups = [
    ChatGroup(id: 'group_1', name: 'Team Alpha', memberIds: ['user_1', 'user_2', 'user_3'], createdAt: DateTime.now().subtract(const Duration(days: 1))),
  ];

  final List<ChatMessage> _mockMessages = [
    ChatMessage(id: 'msg_1', senderId: 'user_2', text: 'Hey everyone!', timestamp: DateTime.now().subtract(const Duration(hours: 2)), groupId: 'group_1'),
    ChatMessage(id: 'msg_2', senderId: 'user_1', text: 'Hello Alice.', timestamp: DateTime.now().subtract(const Duration(hours: 1)), groupId: 'group_1'),
    ChatMessage(id: 'msg_3', senderId: 'user_3', text: 'Sup.', timestamp: DateTime.now().subtract(const Duration(minutes: 30)), groupId: 'group_1'),
    ChatMessage(id: 'msg_4', senderId: 'user_4', text: 'Hey, do you have the roster?', timestamp: DateTime.now().subtract(const Duration(days: 1)), receiverId: 'user_1'),
  ];

  // Streams for UI to listen to
  final _messagesController = StreamController<List<ChatMessage>>.broadcast();
  final _groupsController = StreamController<List<ChatGroup>>.broadcast();

  ChatService() {
    _emitMessages();
    _emitGroups();
  }

  void _emitMessages() {
    _messagesController.add(List.from(_mockMessages));
  }

  void _emitGroups() {
    _groupsController.add(List.from(_mockGroups));
  }

  String get currentUserId => _currentUserId;

  // --- METHODS THAT FRONTEND WILL USE ---

  // Synchronous getters for initial data
  List<ChatGroup> get currentGroups => _mockGroups.where((g) => g.memberIds.contains(_currentUserId)).toList();
  
  List<ChatMessage> getMessagesForChat({String? groupId, String? otherUserId}) {
    if (groupId != null) {
      return _mockMessages.where((m) => m.groupId == groupId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else if (otherUserId != null) {
      return _mockMessages.where((m) => 
        (m.senderId == _currentUserId && m.receiverId == otherUserId) ||
        (m.senderId == otherUserId && m.receiverId == _currentUserId)
      ).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return [];
  }

  /// Get a stream of messages either for a group or a direct user
  Stream<List<ChatMessage>> getMessagesStream({String? groupId, String? otherUserId}) {
    return _messagesController.stream.map((messages) {
      if (groupId != null) {
        return messages.where((m) => m.groupId == groupId).toList()
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      } else if (otherUserId != null) {
        return messages.where((m) => 
          (m.senderId == _currentUserId && m.receiverId == otherUserId) ||
          (m.senderId == otherUserId && m.receiverId == _currentUserId)
        ).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      return <ChatMessage>[];
    });
  }

  /// Send a new message
  Future<void> sendMessage({required String text, String? groupId, String? receiverId}) async {
    final newMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUserId,
      text: text,
      timestamp: DateTime.now(),
      groupId: groupId,
      receiverId: receiverId,
    );
    _mockMessages.add(newMessage);
    _emitMessages();
    // TODO: Backend teammate to implement actual Firebase write
  }

  /// Get groups the current user is a part of
  Stream<List<ChatGroup>> getUserGroups() {
    return _groupsController.stream.map((groups) {
      return groups.where((g) => g.memberIds.contains(_currentUserId)).toList();
    });
  }

  /// Create a new chat group
  Future<void> createGroup(String name, List<String> memberIds) async {
    final newGroup = ChatGroup(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      // Ensure the current user is in the group
      memberIds: {...memberIds, _currentUserId}.toList(),
      createdAt: DateTime.now(),
    );
    _mockGroups.add(newGroup);
    _emitGroups();
    // TODO: Backend teammate to implement actual Firebase write
  }

  /// Fetch a user synchronously (for mock UI labeling)
  AppUser? getUserById(String uid) {
    try {
      return _mockUsers.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }

  /// Fetch all users to start new chats or create groups
  Future<List<AppUser>> getAllUsers() async {
    return _mockUsers;
    // TODO: Backend teammate to implement Firebase read
  }
}
