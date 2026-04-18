import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../backend/models/group.dart';
import '../../backend/models/group_member.dart';
import '../../backend/models/payment_tracker.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/repositories/tracker_repository.dart';

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
    final currentMonth = PaymentTracker.getCurrentMonthKey();

    return Scaffold(
      appBar: AppBar(
        title: Text('${group.name} Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              }
            ),
            const SizedBox(height: 32),
            
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
                final trackers = (snapshot.data ?? []).where((t) => t.billingMonth == currentMonth).toList();
                
                final verified = trackers.where((t) => t.paymentStatus == PaymentStatus.verified).length;
                final pending = trackers.where((t) => t.paymentStatus == PaymentStatus.pending).length;
                
                return Column(
                  children: [
                    Row(
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
