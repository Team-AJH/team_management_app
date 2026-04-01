import 'package:flutter/material.dart';
import '../../backend/services/chat_service.dart';
import '../../backend/models/chat_group.dart';
import '../../backend/models/app_user.dart';
import 'chat_page.dart';
import 'create_group_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ChatService _chatService = ChatService();
  List<AppUser> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _chatService.getAllUsers();
    setState(() {
      _allUsers = users.where((u) => u.uid != _chatService.currentUserId).toList();
      _isLoading = false;
    });
  }

  void _openChat(BuildContext context, {ChatGroup? group, AppUser? user}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatService: _chatService,
          group: group,
          otherUser: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Groups'),
              Tab(text: 'Direct Messages'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGroupsTab(),
                _buildDMsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Stack(
      children: [
        StreamBuilder<List<ChatGroup>>(
          stream: _chatService.getUserGroups(),
          initialData: _chatService.currentGroups,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final groups = snapshot.data!;
            if (groups.isEmpty) {
              return const Center(child: Text('No groups yet. Create one!'));
            }

            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${group.memberIds.length} members'),
                  onTap: () => _openChat(context, group: group),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'group_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateGroupPage(chatService: _chatService),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildDMsTab() {
    // For DMs, we show the list of all users to simulate starting/resuming a chat.
    return ListView.builder(
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blueGrey,
            child: Text(user.displayName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(user.status),
          onTap: () => _openChat(context, user: user),
        );
      },
    );
  }
}
