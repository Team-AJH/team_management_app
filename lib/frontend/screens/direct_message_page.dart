import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../backend/repositories/chat_repository.dart';
import '../../backend/models/chat_message.dart';
import '../../backend/models/app_user.dart';
import '../../backend/data/user_data.dart';

class DirectMessagePage extends StatefulWidget {
  final AppUser otherUser;

  const DirectMessagePage({super.key, required this.otherUser});

  @override
  State<DirectMessagePage> createState() => _DirectMessagePageState();
}

class _DirectMessagePageState extends State<DirectMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    final chatRepo = Provider.of<ChatRepository>(context, listen: false);
    final appUser = await UserData().getUserById(me.uid);
    try {
      await chatRepo.sendDirectMessage(
        fromUid: me.uid,
        fromName: appUser?.displayName ?? me.displayName ?? 'Me',
        toUid: widget.otherUser.uid,
        text: text,
      );
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final chatRepo = Provider.of<ChatRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 16,
              child: Text(
                widget.otherUser.displayName.isNotEmpty
                    ? widget.otherUser.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.displayName,
                      overflow: TextOverflow.ellipsis),
                  const Text('Direct Message',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: me == null
                ? const Center(child: Text('Not signed in'))
                : StreamBuilder<List<ChatMessage>>(
                    stream: chatRepo.getDirectMessagesStream(
                      fromUid: me.uid,
                      toUid: widget.otherUser.uid,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'Send a message to ${widget.otherUser.displayName}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == me.uid;
                          return _MessageBubble(message: msg, isMe: isMe);
                        },
                      );
                    },
                  ),
          ),
          _MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft:
                !isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
