import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/models/group.dart';
import '../../backend/models/group_member.dart';

class RosterPage extends StatelessWidget {
  const RosterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please login to view roster"));
    }

    final groupRepo = Provider.of<GroupRepository>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Roster Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adding players via share link coming soon!')));
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add Player'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Group>>(
              stream: groupRepo.getUserGroups(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return const Center(child: Text('You are not in any team yet.'));
                }

                final currentGroup = groups.first;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team: ${currentGroup.name}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<List<GroupMember>>(
                        stream: groupRepo.getGroupMembers(currentGroup.id),
                        builder: (context, memberSnapshot) {
                          if (memberSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final members = memberSnapshot.data ?? [];
                          if (members.isEmpty) {
                            return const Center(child: Text('No players in this roster.'));
                          }

                          return Card(
                            child: ListView.separated(
                              itemCount: members.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final member = members[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person),
                                  ),
                                  title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Role: ${member.role}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit member feature pending')));
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
