import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/services/chat_service.dart';
import '../../backend/models/chat_message.dart';
import '../../backend/models/chat_group.dart';
import '../../backend/models/app_user.dart';

class ChatPage extends StatefulWidget {
  final ChatService chatService;
  final ChatGroup? group;
  final AppUser? otherUser;

  const ChatPage({
    super.key,
    required this.chatService,
    this.group,
    this.otherUser,
  }) : assert(group != null || otherUser != null);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    widget.chatService.sendMessage(
      text: _messageController.text.trim(),
      groupId: widget.group?.id,
      receiverId: widget.otherUser?.uid,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.group?.name ?? widget.otherUser?.displayName ?? 'Chat';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.chatService.getMessagesStream(
                groupId: widget.group?.id,
                otherUserId: widget.otherUser?.uid,
              ),
              initialData: widget.chatService.getMessagesForChat(
                groupId: widget.group?.id,
                otherUserId: widget.otherUser?.uid,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  reverse: false, // We sorted by time ascending
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.chatService.currentUserId;
                    
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Theme.of(context).primaryColor : Colors.grey[300];
    final textColor = isMe ? Colors.white : Colors.black87;
    
    final bool showSenderName = widget.group != null && !isMe;
    final senderName = showSenderName 
        ? widget.chatService.getUserById(message.senderId)?.displayName ?? 'Unknown User'
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                senderName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isMe ? const Radius.circular(0) : null,
                bottomLeft: !isMe ? const Radius.circular(0) : null,
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('h:mm a').format(message.timestamp),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
