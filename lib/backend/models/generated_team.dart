import 'rated_player.dart';

class GeneratedTeam {
  final String name;
  final List<RatedPlayer> players;

  GeneratedTeam({
    required this.name,
    required this.players,
  });

  double get averageRating {
    if (players.isEmpty) return 0;
    final total = players.fold<double>(
      0,
      (sum, player) => sum + player.overallRating,
    );
    return total / players.length;
  }

  double get totalRating {
    return players.fold<double>(
      0,
      (sum, player) => sum + player.overallRating,
    );
  }
}