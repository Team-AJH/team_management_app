import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../backend/models/group.dart';
import '../../backend/models/event.dart';
import '../../backend/models/group_member.dart';
import '../../backend/models/event_participant.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/repositories/event_repository.dart';
import 'event_detail_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in.'));
    }

    final groupRepo = Provider.of<GroupRepository>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Events',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All past and upcoming events from your groups.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Group>>(
              stream: groupRepo.getUserGroups(user.uid),
              builder: (context, groupSnap) {
                if (groupSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final groups = groupSnap.data ?? [];
                if (groups.isEmpty) {
                  return const Center(
                    child: Text('You are not in any group yet. Join a group to see events.'),
                  );
                }

                return _AllGroupsEventsList(groups: groups, userId: user.uid);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AllGroupsEventsList extends StatelessWidget {
  final List<Group> groups;
  final String userId;

  const _AllGroupsEventsList({required this.groups, required this.userId});

  @override
  Widget build(BuildContext context) {
    final eventRepo = Provider.of<EventRepository>(context, listen: false);

    // Collect stream builders for all groups
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, gi) {
        final group = groups[gi];
        return StreamBuilder<List<Event>>(
          stream: eventRepo.getEventsForGroup(group.id),
          builder: (context, eventSnap) {
            final events = (eventSnap.data ?? [])
                .toList()
              ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

            if (events.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                ...events.map(
                  (event) => _EventCard(
                    event: event,
                    group: group,
                    userId: userId,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final Group group;
  final String userId;

  const _EventCard({
    required this.event,
    required this.group,
    required this.userId,
  });

  Future<void> _join(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Capture before async gap
    final messenger = ScaffoldMessenger.of(context);
    final eventRepo = Provider.of<EventRepository>(context, listen: false);

    // Get the user's GroupMember object
    final memberDoc = await firestore
        .collection('groups')
        .doc(group.id)
        .collection('members')
        .doc(user.uid)
        .get();

    if (!memberDoc.exists) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You are not a member of this group.')),
      );
      return;
    }

    final member = GroupMember.fromMap(memberDoc.data()!);

    // Fetch current participants
    final participantsSnap = await firestore
        .collection('groups')
        .doc(group.id)
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

  void _showParticipants(BuildContext context, List<EventParticipant> participants) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Participants (${participants.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (participants.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No participants yet.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          child: Text(
                            p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                          ),
                        ),
                        title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Joined: ${DateFormat('MMM d, yyyy • h:mm a').format(p.joinedAt)}'),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d • h:mm a').format(event.eventDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: event, groupId: group.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<EventParticipant>>(
              stream: Provider.of<EventRepository>(context, listen: false)
                  .getEventParticipants(group.id, event.id),
              builder: (context, snap) {
                final participants = snap.data ?? [];
                final alreadyJoined =
                    participants.any((p) => p.userId == userId);
                final isFull = participants.length >= event.maxPlayers;

                return Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _showParticipants(context, participants),
                      icon: const Icon(Icons.people, size: 16),
                      label: Text(
                        '${participants.length} / ${event.maxPlayers} players',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: isFull ? Colors.red : Theme.of(context).primaryColor,
                        backgroundColor: (isFull ? Colors.red : Theme.of(context).primaryColor).withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (alreadyJoined)
                      Chip(
                        label: const Text('Joined'),
                        backgroundColor: Colors.green.withValues(alpha: 0.15),
                        labelStyle: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (isFull)
                      Chip(
                        label: const Text('Full'),
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: Colors.red),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _join(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Join'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}
