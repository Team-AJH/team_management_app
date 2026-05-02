import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/models/group.dart';
import '../../backend/models/group_member.dart';
import '../../backend/data/user_data.dart';

class BrowseGroupsPage extends StatefulWidget {
  const BrowseGroupsPage({super.key});

  @override
  State<BrowseGroupsPage> createState() => _BrowseGroupsPageState();
}

class _BrowseGroupsPageState extends State<BrowseGroupsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup(Group group) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final appUser = await UserData().getUserById(user.uid);
    final displayName = appUser?.displayName ?? user.displayName ?? user.email ?? 'Unknown';
    final now = DateTime.now();
    final groupRef = _firestore.collection('groups').doc(group.id);
    final memberRef = groupRef.collection('members').doc(user.uid);

    final batch = _firestore.batch();

    // Add to memberIds array
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([user.uid]),
    });

    // Create member document
    final member = GroupMember(
      userId: user.uid,
      groupId: group.id,
      displayName: displayName,
      role: 'member',
      joinedAt: now,
    );
    batch.set(memberRef, member.toMap());

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${group.name}" successfully!')),
      );
    }
  }

  Future<void> _leaveGroup(Group group, GroupMember myMembership) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);

    if (myMembership.isAdmin()) {
      // Check if last admin
      final members = await _firestore
          .collection('groups')
          .doc(group.id)
          .collection('members')
          .get();
      final admins = members.docs
          .where((d) => (d.data()['role'] as String?) == 'admin')
          .toList();
      if (admins.length <= 1) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'You are the last admin. Transfer admin role before leaving.',
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group?'),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final groupRef = _firestore.collection('groups').doc(group.id);
    final memberRef = groupRef.collection('members').doc(user.uid);

    final batch = _firestore.batch();
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayRemove([user.uid]),
    });
    batch.delete(memberRef);
    await batch.commit();

    messenger.showSnackBar(
      SnackBar(content: Text('Left "${group.name}".')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Groups',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover and join groups to get started.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or sport…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('groups').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allGroups = (snapshot.data?.docs ?? [])
                    .map((d) => Group.fromMap(d.data() as Map<String, dynamic>))
                    .where((g) {
                      if (_searchQuery.isEmpty) return true;
                      return g.name.toLowerCase().contains(_searchQuery) ||
                          g.sportType.toLowerCase().contains(_searchQuery);
                    })
                    .toList();

                if (allGroups.isEmpty) {
                  return const Center(child: Text('No groups found.'));
                }

                return ListView.separated(
                  itemCount: allGroups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final group = allGroups[index];
                    final isMember = group.memberIds.contains(user.uid);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.group,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${group.sportType} • ${group.memberIds.length} members',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (group.description.isNotEmpty)
                                    Text(
                                      group.description,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            isMember
                                ? FutureBuilder<DocumentSnapshot>(
                                    future: _firestore
                                        .collection('groups')
                                        .doc(group.id)
                                        .collection('members')
                                        .doc(user.uid)
                                        .get(),
                                    builder: (ctx, snap) {
                                      GroupMember? myMembership;
                                      if (snap.hasData && snap.data!.exists) {
                                        myMembership = GroupMember.fromMap(
                                          snap.data!.data() as Map<String, dynamic>,
                                        );
                                      }
                                      return OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        onPressed: myMembership == null
                                            ? null
                                            : () => _leaveGroup(group, myMembership!),
                                        child: const Text('Leave'),
                                      );
                                    },
                                  )
                                : ElevatedButton(
                                    onPressed: () => _joinGroup(group),
                                    child: const Text('Join'),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
