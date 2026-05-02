import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/repositories/event_repository.dart';
import '../../backend/repositories/announcement_repository.dart';
import '../../backend/models/group.dart';
import '../../backend/models/event.dart';
import '../../backend/models/announcement.dart';
import '../../backend/repositories/transaction_repository.dart';
import '../../backend/models/transaction_model.dart';
import 'event_detail_page.dart';
import 'transaction_history_page.dart';

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
    final eventRepo = Provider.of<EventRepository>(context, listen: false);
    final announcementRepo = Provider.of<AnnouncementRepository>(
      context,
      listen: false,
    );
    final txnRepo = Provider.of<TransactionRepository>(context, listen: false);

    return StreamBuilder<List<Group>>(
      stream: groupRepo.getUserGroups(user.uid),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = groupSnapshot.data ?? [];
        if (groups.isEmpty) {
          return _buildEmptyState(context);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, user),
              const SizedBox(height: 32),

              // Next Event
              _buildNextEventCard(context, groups, eventRepo),

              const SizedBox(height: 32),

              // Upcoming Events Section
              _buildSectionHeader(
                context,
                'Upcoming Events',
                onTap: () => onNavigate?.call(6),
              ),
              const SizedBox(height: 16),
              _buildEventsHorizontalList(context, groups, eventRepo),

              const SizedBox(height: 32),

              // Group Balances Section
              _buildSectionHeader(
                context,
                'Group Balances',
                onTap: () => onNavigate?.call(3),
              ),
              const SizedBox(height: 16),
              _buildGroupBalancesList(context, groups, txnRepo),

              const SizedBox(height: 32),

              // Recent Announcements
              _buildSectionHeader(
                context,
                'Recent Announcements',
                onTap: () => onNavigate?.call(8),
              ),
              const SizedBox(height: 16),
              _buildAnnouncementsList(context, groups, announcementRepo),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "No Teams Yet",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Join or create a team to start tracking events and payments.",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => onNavigate?.call(5), // Browse Groups
              child: const Text("Explore Teams"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User user) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        String name = "Coach";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['displayName'] ?? "Coach";
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNextEventCard(
    BuildContext context,
    List<Group> groups,
    EventRepository eventRepo,
  ) {
    // Combine events from all groups
    final eventStreams = groups
        .map((g) => eventRepo.getEventsForGroup(g.id))
        .toList();
    final combinedEventsStream = CombineLatestStream.list(
      eventStreams,
    ).map((lists) => lists.expand((x) => x).toList());

    return StreamBuilder<List<Event>>(
      stream: combinedEventsStream,
      builder: (context, snapshot) {
        String title = 'Next Event';
        String value = 'None scheduled';
        if (snapshot.hasData) {
          final now = DateTime.now();
          final upcoming =
              snapshot.data!
                  .where(
                    (e) => e.eventDate.isAfter(now) && e.status == 'scheduled',
                  )
                  .toList()
                ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

          if (upcoming.isNotEmpty) {
            final next = upcoming.first;
            title = DateFormat('MMM d, h:mm a').format(next.eventDate);
            value = next.title;
          }
        }
        return _StatCard(
          title: title,
          value: value,
          icon: Icons.calendar_today_rounded,
          color: Colors.blue,
          onTap: () {
            final now = DateTime.now();
            final upcoming =
                snapshot.data!
                    .where(
                      (e) =>
                          e.eventDate.isAfter(now) && e.status == 'scheduled',
                    )
                    .toList()
                  ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

            if (upcoming.isNotEmpty) {
              final next = upcoming.first;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EventDetailPage(event: next, groupId: next.groupId),
                ),
              );
            } else {
              onNavigate?.call(7);
            }
          },
        );
      },
    );
  }

  Widget _buildGroupBalancesList(
    BuildContext context,
    List<Group> groups,
    TransactionRepository txnRepo,
  ) {
    return Column(
      children: groups.map((group) {
        return StreamBuilder<List<TransactionModel>>(
          stream: txnRepo.getGroupTransactions(group.id),
          builder: (context, snapshot) {
            double totalCollected = 0.0;
            double totalExpenses = 0.0;

            if (snapshot.hasData) {
              for (var txn in snapshot.data!) {
                if (txn.isCollection) {
                  totalCollected += txn.amount;
                } else {
                  totalExpenses += txn.amount;
                }
              }
            }

            final balance = totalCollected - totalExpenses;
            final isPositive = balance >= 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isPositive ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  group.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Account Balance'),
                trailing: Text(
                  '${isPositive ? "" : "-"}\$${balance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionHistoryPage(groupId: group.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('View All')),
      ],
    );
  }

  Widget _buildEventsHorizontalList(
    BuildContext context,
    List<Group> groups,
    EventRepository eventRepo,
  ) {
    final eventStreams = groups
        .map((g) => eventRepo.getEventsForGroup(g.id))
        .toList();

    return StreamBuilder<List<List<Event>>>(
      stream: CombineLatestStream.list(eventStreams),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);

        // Flatten and filter
        final now = DateTime.now();
        final allEvents = <Map<String, dynamic>>[];
        for (int i = 0; i < groups.length; i++) {
          for (final e in snapshot.data![i]) {
            if (e.eventDate.isAfter(now) && e.status == 'scheduled') {
              allEvents.add({'event': e, 'group': groups[i]});
            }
          }
        }

        allEvents.sort(
          (a, b) => (a['event'] as Event).eventDate.compareTo(
            (b['event'] as Event).eventDate,
          ),
        );

        if (allEvents.isEmpty) {
          return _buildEmptySection('No upcoming events');
        }

        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allEvents.length.clamp(0, 5),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = allEvents[index];
              final event = item['event'] as Event;
              final group = item['group'] as Group;
              return _EventSummaryCard(event: event, group: group);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsList(
    BuildContext context,
    List<Group> groups,
    AnnouncementRepository announcementRepo,
  ) {
    final streams = groups
        .map((g) => announcementRepo.getAnnouncementsForGroup(g.id))
        .toList();

    return StreamBuilder<List<List<Announcement>>>(
      stream: CombineLatestStream.list(streams),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);

        final allAnnouncements = snapshot.data!.expand((x) => x).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (allAnnouncements.isEmpty) {
          return _buildEmptySection('No recent announcements');
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allAnnouncements.length.clamp(0, 3),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final announcement = allAnnouncements[index];
            final groupName = groups
                .firstWhere((g) => g.id == announcement.groupId)
                .name;
            return _AnnouncementSummaryItem(
              announcement: announcement,
              groupName: groupName,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.8), color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventSummaryCard extends StatelessWidget {
  final Event event;
  final Group group;

  const _EventSummaryCard({required this.event, required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EventDetailPage(event: event, groupId: event.groupId),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEE, MMM d • h:mm a').format(event.eventDate),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementSummaryItem extends StatelessWidget {
  final Announcement announcement;
  final String groupName;

  const _AnnouncementSummaryItem({
    required this.announcement,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.campaign_rounded,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          announcement.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              announcement.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${timeago(announcement.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String timeago(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}
