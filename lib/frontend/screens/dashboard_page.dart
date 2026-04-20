import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/repositories/event_repository.dart';
import '../../backend/repositories/tracker_repository.dart';
import '../../backend/models/group.dart';
import '../../backend/models/event.dart';
import '../../backend/models/payment_tracker.dart';

class DashboardPage extends StatelessWidget {
  final Function(int)? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please sign in to view dashboard"));
    }

    final groupRepo = Provider.of<GroupRepository>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {
              String name = "Coach";
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null &&
                    data['displayName'] != null &&
                    data['displayName'].toString().trim().isNotEmpty) {
                  name = data['displayName'];
                }
              }
              return Text(
                'Welcome, $name',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Here is the status of your team for this week.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          StreamBuilder<List<Group>>(
            stream: groupRepo.getUserGroups(user.uid),
            builder: (context, groupSnapshot) {
              if (groupSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final groups = groupSnapshot.data ?? [];
              if (groups.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        "You are not part of any group yet.\nPlease join or create a team.",
                      ),
                    ),
                  ),
                );
              }

              // We pick the first group for the dashboard summary
              final group = groups.first;

              return Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                    children: [
                      // Next Game
                      StreamBuilder<List<Event>>(
                        stream: Provider.of<EventRepository>(
                          context,
                          listen: false,
                        ).getEventsForGroup(group.id),
                        builder: (context, eventSnap) {
                          String cardTitle = 'Next Event';
                          String nextGameValue = 'None';
                          if (eventSnap.hasData && eventSnap.data!.isNotEmpty) {
                            final now = DateTime.now();
                            final upcoming = eventSnap.data!
                                .where((e) => e.eventDate.isAfter(now) && e.status == 'scheduled')
                                .toList();
                            if (upcoming.isNotEmpty) {
                              upcoming.sort(
                                (a, b) => a.eventDate.compareTo(b.eventDate),
                              );
                              final nextEvent = upcoming.first;
                              cardTitle = 'Next: ${DateFormat('MMM d, h:mm a').format(nextEvent.eventDate)}';
                              nextGameValue = nextEvent.title;
                            }
                          }
                          return _DashboardCard(
                            title: cardTitle,
                            value: nextGameValue,
                            icon: Icons.calendar_month,
                            onTap: () {
                              if (onNavigate != null) {
                                onNavigate!(7); // Index 7 is Events
                              }
                            },
                          );
                        },
                      ),

                      // Pending Dues
                      StreamBuilder<List<PaymentTracker>>(
                        stream: Provider.of<TrackerRepository>(
                          context,
                          listen: false,
                        ).getTrackersForGroup(group.id),
                        builder: (context, trackerSnap) {
                          String pendingValue = '0';
                          if (trackerSnap.hasData) {
                            final currentMonth =
                                PaymentTracker.getCurrentMonthKey();
                            final pendingCount = trackerSnap.data!
                                .where(
                                  (t) =>
                                      t.billingMonth == currentMonth &&
                                      t.paymentStatus == PaymentStatus.pending,
                                )
                                .length;
                            pendingValue = '$pendingCount Users';
                          }
                          return _DashboardCard(
                            title: 'Pending Payments',
                            value: pendingValue,
                            icon: Icons.attach_money,
                            onTap: () {
                              if (onNavigate != null) {
                                onNavigate!(4); // Index 4 is Team Expenses
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          Text(
            'Recent Notifications',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.notifications)),
                  title: Text('Welcome to Team Management! - Day $index'),
                  subtitle: const Text(
                    'Ensure you start taking advantage of tracking payments and events.',
                  ),
                  trailing: const Text('2h ago'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
