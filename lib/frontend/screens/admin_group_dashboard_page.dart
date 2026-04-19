import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../backend/models/group.dart';
import '../../backend/models/group_member.dart';
import '../../backend/models/group_member_admin_view.dart';
import '../../backend/models/payment_tracker.dart';
import '../../backend/models/event.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/repositories/event_repository.dart';
import '../../backend/repositories/tracker_repository.dart';
import '../../backend/services/group_management_service.dart';
import 'create_event_page.dart';
import 'admin_event_detail_page.dart';
import 'team_generation_page.dart';

class AdminGroupDashboardPage extends StatelessWidget {
  final Group group;

  const AdminGroupDashboardPage({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final groupRepo = Provider.of<GroupRepository>(context, listen: false);
    final trackerRepo = Provider.of<TrackerRepository>(context, listen: false);
    final eventRepo = Provider.of<EventRepository>(context, listen: false);
    final currentMonth = PaymentTracker.getCurrentMonthKey();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('${group.name} Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User Summaries ────────────────────────────────────────────
            Text(
              'User Summaries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<GroupMember>>(
              stream: groupRepo.getGroupMembers(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = snapshot.data ?? [];
                final activePlayers = members.length;

                return Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Users',
                        value: members.length.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Active Players',
                        value: activePlayers.toString(),
                        icon: Icons.person_pin_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // ── Payment Summaries ─────────────────────────────────────────
            Text(
              'Payment Summaries ($currentMonth)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<PaymentTracker>>(
              stream: trackerRepo.getTrackersForGroup(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final trackers = (snapshot.data ?? [])
                    .where((t) => t.billingMonth == currentMonth)
                    .toList();

                final verified = trackers
                    .where((t) => t.paymentStatus == PaymentStatus.verified)
                    .length;
                final pending = trackers
                    .where((t) => t.paymentStatus == PaymentStatus.pending)
                    .length;

                return Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Verified Payments',
                        value: verified.toString(),
                        icon: Icons.check_circle_outline,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pending / Outstanding',
                        value: pending.toString(),
                        icon: Icons.access_time,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // ── Manage Members ────────────────────────────────────────────
            Text(
              'Manage Members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<GroupMember>>(
              stream: groupRepo.getGroupMembers(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = snapshot.data ?? [];
                if (members.isEmpty) {
                  return const Text('No members yet.');
                }

                // Build admin views
                final actingMember = members.firstWhere(
                  (m) => m.userId == currentUser?.uid,
                  orElse: () => GroupMember(
                    userId: currentUser?.uid ?? '',
                    groupId: group.id,
                    displayName: 'Admin',
                    role: 'admin',
                    joinedAt: DateTime.now(),
                  ),
                );

                final managementService = GroupManagementService();
                List<GroupMemberAdminView> adminViews;
                try {
                  adminViews = managementService.buildMemberAdminViews(
                    actingMember: actingMember,
                    members: members,
                  );
                } catch (_) {
                  adminViews = [];
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: adminViews.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final view = adminViews[index];
                      final member = members.firstWhere(
                        (m) => m.userId == view.userId,
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          child: Text(
                            view.displayName.isNotEmpty
                                ? view.displayName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(view.displayName),
                        subtitle: Text(
                          view.role == 'admin' ? '👑 Admin' : 'Member',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (view.canPromoteToAdmin)
                              IconButton(
                                icon: const Icon(Icons.arrow_upward,
                                    color: Colors.green),
                                tooltip: 'Promote to Admin',
                                onPressed: () => _promoteToAdmin(
                                  context,
                                  actingMember,
                                  member,
                                  members,
                                ),
                              ),
                            if (view.canDemoteToMember)
                              IconButton(
                                icon: const Icon(Icons.arrow_downward,
                                    color: Colors.orange),
                                tooltip: 'Demote to Member',
                                onPressed: () => _demoteToMember(
                                  context,
                                  actingMember,
                                  member,
                                  members,
                                ),
                              ),
                            if (view.canRemove)
                              IconButton(
                                icon: const Icon(Icons.person_remove,
                                    color: Colors.red),
                                tooltip: 'Remove Member',
                                onPressed: () => _removeMember(
                                  context,
                                  actingMember,
                                  member,
                                  members,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // ── Events ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Events',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    // Fetch current user's group membership
                    final memberDoc = await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(group.id)
                        .collection('members')
                        .doc(user.uid)
                        .get();

                    if (!memberDoc.exists || !context.mounted) return;

                    final actingMember =
                        GroupMember.fromMap(memberDoc.data()!);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateEventPage(
                          group: group,
                          actingMember: actingMember,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Event'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Event>>(
              stream: eventRepo.getEventsForGroup(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return const Text('No events yet.');
                }

                events.sort((a, b) => b.eventDate.compareTo(a.eventDate));

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final dateStr = DateFormat('MMM d • h:mm a')
                          .format(event.eventDate);
                      final statusColor = event.status == 'cancelled'
                          ? Colors.red
                          : event.status == 'completed'
                              ? Colors.green
                              : Colors.blue;

                      return ListTile(
                        leading: Icon(Icons.event, color: statusColor),
                        title: Text(event.title),
                        subtitle: Text(dateStr),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminEventDetailPage(
                              event: event,
                              groupId: group.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // ── Team Generation ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team Generator',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    final memberDoc = await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(group.id)
                        .collection('members')
                        .doc(user.uid)
                        .get();

                    if (!memberDoc.exists || !context.mounted) return;

                    final actingMember =
                        GroupMember.fromMap(memberDoc.data()!);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamGenerationPage(
                          group: group,
                          actingMember: actingMember,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Generate Teams'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate balanced teams based on player ratings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _promoteToAdmin(
    BuildContext context,
    GroupMember actingMember,
    GroupMember target,
    List<GroupMember> allMembers,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote to Admin?'),
        content: Text('Give ${target.displayName} admin privileges?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.id)
          .collection('members')
          .doc(target.userId)
          .update({'role': 'admin'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${target.displayName} promoted to admin.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _demoteToMember(
    BuildContext context,
    GroupMember actingMember,
    GroupMember target,
    List<GroupMember> allMembers,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demote to Member?'),
        content: Text('Remove admin role from ${target.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Demote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.id)
          .collection('members')
          .doc(target.userId)
          .update({'role': 'member'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${target.displayName} demoted to member.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    GroupMember actingMember,
    GroupMember target,
    List<GroupMember> allMembers,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Remove ${target.displayName} from ${group.name}? They can rejoin later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(group.id);
      final batch = FirebaseFirestore.instance.batch();

      batch.delete(groupRef.collection('members').doc(target.userId));
      batch.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([target.userId]),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${target.displayName} removed.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
