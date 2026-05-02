import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/models/group.dart';
import '../../backend/models/group_member.dart';
import '../../backend/models/player_rating.dart';
import '../../backend/models/group_rating.dart';
import '../../backend/models/rating_parameter.dart';
import '../../backend/services/rating_service.dart';

class PlayerRatingsPage extends StatefulWidget {
  const PlayerRatingsPage({super.key});

  @override
  State<PlayerRatingsPage> createState() => _PlayerRatingsPageState();
}

class _PlayerRatingsPageState extends State<PlayerRatingsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _ratingService = RatingService();

  bool _isLoading = true;
  List<Group> _groups = [];
  Group? _selectedGroup;
  bool _isAdmin = false;

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
        _selectedGroup = groups.isNotEmpty ? groups.first : null;
        _isLoading = false;
      });

      if (_selectedGroup != null) {
        await _checkAdminStatus(_selectedGroup!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAdminStatus(Group group) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final memberDoc = await _firestore
        .collection('groups')
        .doc(group.id)
        .collection('members')
        .doc(user.uid)
        .get();

    if (memberDoc.exists) {
      final role = memberDoc.data()?['role'] as String? ?? 'member';
      setState(() => _isAdmin = role == 'admin');
    }
  }

  Future<GroupRating?> _getOrCreateRatingConfig(String groupId) async {
    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('config')
        .doc('ratings')
        .get();

    if (doc.exists) {
      return GroupRating.fromMap(doc.data()!);
    }

    // Default parameters if none configured
    final defaultConfig = GroupRating(
      groupId: groupId,
      parameters: [
        RatingParameter(id: 'speed', name: 'Speed'),
        RatingParameter(id: 'skill', name: 'Skill'),
        RatingParameter(id: 'teamwork', name: 'Teamwork'),
      ],
    );

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('config')
        .doc('ratings')
        .set(defaultConfig.toMap());

    return defaultConfig;
  }

  Future<void> _showRatingDialog(
    GroupMember member,
    GroupRating config,
    PlayerRating? existing,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final scores = <String, double>{
      for (final p in config.parameters)
        p.id: (existing?.parameterScores[p.id] ?? 5).toDouble(),
    };

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Rate ${member.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: config.parameters.map((param) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(param.name),
                        Text(
                          scores[param.id]!.toInt().toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: scores[param.id]!,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: scores[param.id]!.toInt().toString(),
                      onChanged: (v) => setS(() => scores[param.id] = v),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final intScores = scores.map(
                  (k, v) => MapEntry(k, v.toInt()),
                );

                try {
                  final ratingId = '${user.uid}_${member.userId}';
                  final rating = _ratingService.createPlayerRating(
                    id: ratingId,
                    groupId: _selectedGroup!.id,
                    playerId: member.userId,
                    ratedBy: user.uid,
                    parameterScores: intScores,
                    createdAt: DateTime.now(),
                    config: config,
                  );

                  await _firestore
                      .collection('groups')
                      .doc(_selectedGroup!.id)
                      .collection('ratings')
                      .doc(ratingId)
                      .set(rating.toMap());

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rating saved for ${member.displayName}'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
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
      return const Center(child: Text('Join a group to see player ratings.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player Ratings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Group selector
          DropdownButton<Group>(
            value: _selectedGroup,
            isExpanded: true,
            items: _groups
                .map(
                  (g) => DropdownMenuItem(value: g, child: Text(g.name)),
                )
                .toList(),
            onChanged: (g) async {
              setState(() => _selectedGroup = g);
              if (g != null) await _checkAdminStatus(g);
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _selectedGroup == null
                ? const Center(child: Text('Select a group.'))
                : _RatingsList(
                    group: _selectedGroup!,
                    isAdmin: _isAdmin,
                    onRate: _showRatingDialog,
                    getConfig: _getOrCreateRatingConfig,
                    ratingService: _ratingService,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RatingsList extends StatelessWidget {
  final Group group;
  final bool isAdmin;
  final Future<void> Function(GroupMember, GroupRating, PlayerRating?) onRate;
  final Future<GroupRating?> Function(String) getConfig;
  final RatingService ratingService;

  const _RatingsList({
    required this.group,
    required this.isAdmin,
    required this.onRate,
    required this.getConfig,
    required this.ratingService,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('groups')
          .doc(group.id)
          .collection('members')
          .snapshots(),
      builder: (context, memberSnap) {
        final members = (memberSnap.data?.docs ?? [])
            .map((d) => GroupMember.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        if (members.isEmpty) {
          return const Center(child: Text('No members in this group.'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('groups')
              .doc(group.id)
              .collection('ratings')
              .snapshots(),
          builder: (context, ratingSnap) {
            final allRatings = (ratingSnap.data?.docs ?? [])
                .map((d) => PlayerRating.fromMap(d.data() as Map<String, dynamic>))
                .toList();

            final ratingsByPlayer = <String, List<PlayerRating>>{};
            for (final r in allRatings) {
              ratingsByPlayer.putIfAbsent(r.playerId, () => []).add(r);
            }

            return Card(
              child: ListView.separated(
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final memberRatings = ratingsByPlayer[member.userId] ?? [];

                  double? avgRating;
                  if (memberRatings.isNotEmpty) {
                    avgRating = ratingService
                        .calculateAverageOverallFromRatings(memberRatings);
                  }

                  // My rating for this player
                  final myRating = memberRatings
                      .where((r) => r.ratedBy == currentUid)
                      .toList();
                  final myExisting = myRating.isNotEmpty ? myRating.first : null;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        member.displayName.isNotEmpty
                            ? member.displayName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      member.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Role: ${member.role}'),
                        if (avgRating != null)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                'Avg: ${avgRating.toStringAsFixed(1)}/10 (${memberRatings.length} ratings)',
                                style: const TextStyle(color: Colors.amber),
                              ),
                            ],
                          )
                        else
                          const Text('No ratings yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    trailing: member.userId != currentUid
                        ? IconButton(
                            icon: Icon(
                              myExisting != null ? Icons.edit : Icons.star_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                            tooltip: myExisting != null ? 'Edit Rating' : 'Rate Player',
                            onPressed: () async {
                              final config = await getConfig(group.id);
                              if (config != null && context.mounted) {
                                onRate(member, config, myExisting);
                              }
                            },
                          )
                        : null,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
