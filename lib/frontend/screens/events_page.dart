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
            'Upcoming Events',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Events from all your groups.',
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
            final now = DateTime.now();
            final events = (eventSnap.data ?? [])
                .where((e) => e.eventDate.isAfter(now) && e.status == 'scheduled')
                .toList()
              ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

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

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d • h:mm a').format(event.eventDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    Text(
                      '${participants.length} / ${event.maxPlayers} players',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isFull ? Colors.red : Colors.grey[600],
                        fontWeight: FontWeight.w600,
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
    );
  }
}
