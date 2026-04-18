import '../models/chat_message.dart';
import '../models/group_member.dart';
import 'group_permissions_service.dart';

class ChatService {
  final GroupPermissionsService _permissionsService =
      GroupPermissionsService();

  ChatMessage createMessage({
    required GroupMember member,
    required String id,
    required String groupId,
    required String message,
    required DateTime createdAt,
  }) {
    _permissionsService.enforceCanSendMessage(member);

    final chatMessage = ChatMessage(
      id: id,
      groupId: groupId,
      senderId: member.userId,
      senderName: member.displayName,
      message: message,
      createdAt: createdAt,
    );

    chatMessage.validate();

    return chatMessage;
  }
}
