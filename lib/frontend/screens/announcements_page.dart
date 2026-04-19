import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../backend/models/group.dart';
import '../../backend/models/group_member.dart';
import '../../backend/models/announcement.dart';
import '../../backend/services/announcement_service.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _announcementService = AnnouncementService();

  bool _isLoading = true;
  List<Group> _groups = [];
  Group? _selectedGroup;
  GroupMember? _myMembership;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final snap = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: user.uid)
          .get();

      final groups = snap.docs
          .map((d) => Group.fromMap(d.data()))
          .toList();

      setState(() {
        _groups = groups;
        _isLoading = false;
      });

      if (groups.isNotEmpty) {
        await _selectGroup(groups.first);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectGroup(Group group) async {
    setState(() => _selectedGroup = group);

    final user = _auth.currentUser;
    if (user == null) return;

    final memberDoc = await _firestore
        .collection('groups')
        .doc(group.id)
        .collection('members')
        .doc(user.uid)
        .get();

    if (memberDoc.exists && mounted) {
      setState(() {
        _myMembership = GroupMember.fromMap(memberDoc.data()!);
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final user = _auth.currentUser;
    if (user == null || _myMembership == null || _selectedGroup == null) return;

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLength: 1000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Content *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty ||
                          contentController.text.trim().isEmpty) {
                        return;
                      }
                      setS(() => isSaving = true);
                      try {
                        final docRef = _firestore
                            .collection('groups')
                            .doc(_selectedGroup!.id)
                            .collection('announcements')
                            .doc();

                        final announcement =
                            _announcementService.createAnnouncement(
                          member: _myMembership!,
                          id: docRef.id,
                          groupId: _selectedGroup!.id,
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        await docRef.set(announcement.toMap());

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Announcement posted!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setS(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groups.isEmpty) {
      return const Center(
        child: Text('Join a group to see announcements.'),
      );
    }

    final isAdmin = _myMembership?.isAdmin() ?? false;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Announcements',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<Group>(
              value: _selectedGroup,
              isExpanded: true,
              underline: Container(
                height: 1,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
              items: _groups
                  .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                  .toList(),
              onChanged: (g) {
                if (g != null) _selectGroup(g);
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _selectedGroup == null
                  ? const SizedBox.shrink()
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('groups')
                          .doc(_selectedGroup!.id)
                          .collection('announcements')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('No announcements yet.'),
                          );
                        }

                        final announcements = docs
                            .map(
                              (d) => Announcement.fromMap(
                                d.data() as Map<String, dynamic>,
                              ),
                            )
                            .toList();

                        return ListView.separated(
                          itemCount: announcements.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final a = announcements[index];
                            return _AnnouncementCard(announcement: a);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Announcement'),
            )
          : null,
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(announcement.createdAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.campaign,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(announcement.content),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  announcement.createdByName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
