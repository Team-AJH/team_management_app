import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/repositories/user_repository.dart';
import '../../backend/models/group.dart';
import '../../backend/models/app_user.dart';
import 'chat_page.dart';
import 'direct_message_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view messages'));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Messages'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group), text: 'Groups'),
              Tab(icon: Icon(Icons.person), text: 'Direct'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GroupChatsTab(userId: user.uid),
            _DirectChatsTab(currentUser: user),
          ],
        ),
      ),
    );
  }
}

// ── Group Chats Tab ────────────────────────────────────────────────────────

class _GroupChatsTab extends StatelessWidget {
  final String userId;
  const _GroupChatsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final groupRepo = Provider.of<GroupRepository>(context, listen: false);

    return StreamBuilder<List<Group>>(
      stream: groupRepo.getUserGroups(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return const Center(
            child: Text(
              'No groups found.\nCreate or join a team to start chatting!',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          itemCount: groups.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final group = groups[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.group, color: Colors.white),
              ),
              title: Text(group.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                group.sportType.isNotEmpty ? group.sportType : 'Group Chat',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatPage(group: group)),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Direct Chats Tab ───────────────────────────────────────────────────────

class _DirectChatsTab extends StatelessWidget {
  final User currentUser;
  const _DirectChatsTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final userRepo = Provider.of<UserRepository>(context, listen: false);

    return FutureBuilder<List<AppUser>>(
      future: userRepo.getKnownUsers(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No contacts yet.\nJoin a group to discover teammates!',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final other = users[index];
            final initial = other.displayName.isNotEmpty
                ? other.displayName[0].toUpperCase()
                : '?';

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  initial,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(other.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DirectMessagePage(otherUser: other),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
