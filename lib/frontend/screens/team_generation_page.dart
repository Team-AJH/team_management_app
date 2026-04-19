import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/models/group.dart';
import '../../backend/models/group_member.dart';
import '../../backend/models/player_rating.dart';
import '../../backend/models/generated_team.dart';
import '../../backend/services/team_generation_service.dart';
import '../../backend/services/rating_service.dart';

class TeamGenerationPage extends StatefulWidget {
  final Group group;
  final GroupMember actingMember;

  const TeamGenerationPage({
    super.key,
    required this.group,
    required this.actingMember,
  });

  @override
  State<TeamGenerationPage> createState() => _TeamGenerationPageState();
}

class _TeamGenerationPageState extends State<TeamGenerationPage> {
  final _firestore = FirebaseFirestore.instance;
  final _teamGenService = TeamGenerationService();
  final _ratingService = RatingService();

  List<GroupMember> _members = [];
  Map<String, List<PlayerRating>> _ratingsByPlayerId = {};
  Set<String> _selectedPlayerIds = {};

  bool _isLoading = true;
  bool _isGenerating = false;
  GeneratedTeam? _teamA;
  GeneratedTeam? _teamB;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load members
      final membersSnap = await _firestore
          .collection('groups')
          .doc(widget.group.id)
          .collection('members')
          .get();

      final members = membersSnap.docs
          .map((d) => GroupMember.fromMap(d.data()))
          .toList();

      // Load all ratings for group
      final ratingsSnap = await _firestore
          .collection('groups')
          .doc(widget.group.id)
          .collection('ratings')
          .get();

      final Map<String, List<PlayerRating>> ratingsByPlayer = {};
      for (var doc in ratingsSnap.docs) {
        final rating = PlayerRating.fromMap(doc.data());
        ratingsByPlayer.putIfAbsent(rating.playerId, () => []).add(rating);
      }

      setState(() {
        _members = members;
        _ratingsByPlayerId = ratingsByPlayer;
        _selectedPlayerIds = members.map((m) => m.userId).toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _generateTeams() {
    final selectedMembers =
        _members.where((m) => _selectedPlayerIds.contains(m.userId)).toList();

    // Filter to only players with ratings
    final ratedPlayerIds = _ratingsByPlayerId.keys.toSet();
    final participatingRatings = {
      for (final id in _selectedPlayerIds)
        if (ratedPlayerIds.contains(id)) id: _ratingsByPlayerId[id]!,
    };

    if (participatingRatings.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'At least 2 selected players must have ratings to generate teams.',
          ),
        ),
      );
      return;
    }

    final displayNames = {
      for (final m in selectedMembers) m.userId: m.displayName,
    };

    setState(() => _isGenerating = true);

    try {
      final result = _teamGenService.generateBalancedTeamsFromRatings(
        displayNamesByUserId: displayNames,
        ratingsByPlayerId: participatingRatings,
      );

      setState(() {
        _teamA = result.teamA;
        _teamB = result.teamB;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Generator')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Participating Players',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only players with ratings will be assigned to teams.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: _members.map((member) {
                        final hasRating =
                            _ratingsByPlayerId.containsKey(member.userId);
                        final avgRating = hasRating
                            ? _ratingService.calculateAverageOverallFromRatings(
                                _ratingsByPlayerId[member.userId]!,
                              )
                            : null;

                        return CheckboxListTile(
                          value: _selectedPlayerIds.contains(member.userId),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedPlayerIds.add(member.userId);
                              } else {
                                _selectedPlayerIds.remove(member.userId);
                              }
                            });
                          },
                          title: Text(member.displayName),
                          subtitle: Text(
                            hasRating
                                ? 'Rating: ${avgRating!.toStringAsFixed(1)}/10'
                                : 'No rating — will be excluded',
                            style: TextStyle(
                              color: hasRating ? Colors.green : Colors.orange,
                            ),
                          ),
                          secondary: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              member.displayName.isNotEmpty
                                  ? member.displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateTeams,
                      icon: _isGenerating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shuffle),
                      label: Text(
                        (_teamA == null) ? 'Generate Teams' : 'Regenerate',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  if (_teamA != null && _teamB != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Generated Teams',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _TeamCard(team: _teamA!, color: Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _TeamCard(team: _teamB!, color: Colors.orange)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final GeneratedTeam team;
  final Color color;

  const _TeamCard({required this.team, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'Avg: ${team.averageRating.toStringAsFixed(1)}/10',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const Divider(),
            ...team.players.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        p.displayName.isNotEmpty
                            ? p.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.displayName)),
                    Text(
                      p.overallRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
