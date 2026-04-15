import '../models/player_rating.dart';
import '../models/rated_player.dart';
import '../models/generated_team.dart';
import '../models/team_generation_result.dart';
import 'rating_service.dart';

class TeamGenerationService {
  final RatingService _ratingService = RatingService();

  List<RatedPlayer> buildRatedPlayers({
    required Map<String, String> displayNamesByUserId,
    required Map<String, List<PlayerRating>> ratingsByPlayerId,
  }) {
    return ratingsByPlayerId.entries.map((entry) {
      final userId = entry.key;
      final ratings = entry.value;

      final averageOverall =
          _ratingService.calculateAverageOverallFromRatings(ratings);

      return RatedPlayer(
        userId: userId,
        displayName: displayNamesByUserId[userId] ?? 'Unknown Player',
        overallRating: averageOverall,
      );
    }).toList();
  }

  TeamGenerationResult generateBalancedTeams({
    required List<RatedPlayer> players,
    String teamAName = 'Team A',
    String teamBName = 'Team B',
  }) {
    if (players.length < 2) {
      throw Exception('At least two players are required to generate teams.');
    }

    for (final player in players) {
      player.validate();
    }

    final sortedPlayers = [...players]
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));

    final teamAPlayers = <RatedPlayer>[];
    final teamBPlayers = <RatedPlayer>[];

    double teamATotal = 0;
    double teamBTotal = 0;

    for (final player in sortedPlayers) {
      if (teamATotal <= teamBTotal) {
        teamAPlayers.add(player);
        teamATotal += player.overallRating;
      } else {
        teamBPlayers.add(player);
        teamBTotal += player.overallRating;
      }
    }

    return TeamGenerationResult(
      teamA: GeneratedTeam(
        name: teamAName,
        players: teamAPlayers,
      ),
      teamB: GeneratedTeam(
        name: teamBName,
        players: teamBPlayers,
      ),
    );
  }

  TeamGenerationResult generateBalancedTeamsFromRatings({
    required Map<String, String> displayNamesByUserId,
    required Map<String, List<PlayerRating>> ratingsByPlayerId,
    String teamAName = 'Team A',
    String teamBName = 'Team B',
  }) {
    final ratedPlayers = buildRatedPlayers(
      displayNamesByUserId: displayNamesByUserId,
      ratingsByPlayerId: ratingsByPlayerId,
    );

    return generateBalancedTeams(
      players: ratedPlayers,
      teamAName: teamAName,
      teamBName: teamBName,
    );
  }
}