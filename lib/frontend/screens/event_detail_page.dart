import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../backend/models/event.dart';
import '../../backend/models/event_participant.dart';
import '../../backend/models/group_member.dart';
import '../../backend/repositories/event_repository.dart';

class EventDetailPage extends StatelessWidget {
  final Event event;
  final String groupId;

  const EventDetailPage({
    super.key,
    required this.event,
    required this.groupId,
  });

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final label = newStatus == 'cancelled' ? 'Cancel' : 'Complete';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label Event?'),
        content: Text(
          'Mark "${event.title}" as $newStatus?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus == 'cancelled' ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .doc(event.id)
        .update({'status': newStatus});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event marked as $newStatus.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _joinEvent(BuildContext context, GroupMember member) async {
    final eventRepo = Provider.of<EventRepository>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    // Fetch current participants to check if full
    final participantsSnap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .doc(event.id)
        .collection('participants')
        .get();

    final currentParticipants = participantsSnap.docs
        .map((d) => EventParticipant.fromMap(d.data()))
        .toList();

    try {
      await eventRepo.joinEvent(
        member: member,
        event: event,
        currentParticipants: currentParticipants,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Joined "${event.title}"!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _leaveEvent(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Event?'),
        content: const Text('Are you sure you want to leave this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('events')
          .doc(event.id)
          .collection('participants')
          .doc(userId)
          .delete();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left event.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(event.eventDate);
    final eventRepo = Provider.of<EventRepository>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Scaffold(body: Center(child: Text("Please sign in")));

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: FutureBuilder<GroupMember?>(
        future: _getMember(currentUser.uid),
        builder: (context, memberSnap) {
          final actingMember = memberSnap.data;
          final isAdmin = actingMember?.role == 'admin';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge & Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(event.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _statusColor(event.status),
                        ),
                      ),
                    ),
                    if (event.status == 'scheduled' && actingMember != null)
                      StreamBuilder<List<EventParticipant>>(
                        stream: eventRepo.getEventParticipants(groupId, event.id),
                        builder: (context, snap) {
                          final participants = snap.data ?? [];
                          final isJoined = participants.any((p) => p.userId == currentUser.uid);
                          final isFull = participants.length >= event.maxPlayers;

                          if (isJoined) {
                            return TextButton.icon(
                              onPressed: () => _leaveEvent(context, currentUser.uid),
                              icon: const Icon(Icons.exit_to_app, color: Colors.red),
                              label: const Text('Leave', style: TextStyle(color: Colors.red)),
                            );
                          } else if (!isFull) {
                            return ElevatedButton.icon(
                              onPressed: () => _joinEvent(context, actingMember),
                              icon: const Icon(Icons.add),
                              label: const Text('Join Event'),
                            );
                          } else {
                            return const Chip(label: Text('Event Full'));
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info cards
                _InfoCard(
                  icon: Icons.calendar_today, 
                  title: 'Date & Time',
                  content: dateStr,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.location_on, 
                  title: 'Location',
                  content: event.location,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.people, 
                  title: 'Max Players',
                  content: '${event.maxPlayers} players allowed',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.receipt, 
                  title: 'Billing Month',
                  content: event.billingMonth,
                ),
                const SizedBox(height: 32),

                if (event.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<EventParticipant>>(
                  stream: eventRepo.getEventParticipants(groupId, event.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final participants = snap.data ?? [];
                    if (participants.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No participants yet.',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: participants.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = participants[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              'Joined ${DateFormat('MMM d, h:mm a').format(p.joinedAt)}',
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                if (isAdmin && event.status == 'scheduled') ...[
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    'Admin Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _updateStatus(context, 'cancelled'),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel Event'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _updateStatus(context, 'completed'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark Complete'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<GroupMember?> _getMember(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return GroupMember.fromMap(doc.data()!);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
