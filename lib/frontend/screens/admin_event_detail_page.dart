import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../backend/models/event.dart';
import '../../backend/models/event_participant.dart';
import '../../backend/repositories/event_repository.dart';

class AdminEventDetailPage extends StatelessWidget {
  final Event event;
  final String groupId;

  const AdminEventDetailPage({
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

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(event.eventDate);
    final eventRepo = Provider.of<EventRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
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
            const SizedBox(height: 16),

            // Info cards
            _InfoRow(icon: Icons.calendar_today, text: dateStr),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.location_on, text: event.location),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.people,
              text: 'Max players: ${event.maxPlayers}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.receipt,
              text: 'Billing month: ${event.billingMonth}',
            ),
            const SizedBox(height: 16),

            if (event.description.isNotEmpty) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(event.description),
              const SizedBox(height: 24),
            ],

            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<EventParticipant>>(
              stream: eventRepo.getEventParticipants(groupId, event.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final participants = snap.data ?? [];
                if (participants.isEmpty) {
                  return const Text('No participants yet.');
                }
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: participants.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(p.displayName),
                        subtitle: Text(
                          'Joined: ${DateFormat('MMM d, h:mm a').format(p.joinedAt)}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            if (event.status == 'scheduled') ...[
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
            ],
          ],
        ),
      ),
    );
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
