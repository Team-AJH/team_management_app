import 'generated_team.dart';

class TeamGenerationResult {
  final GeneratedTeam teamA;
  final GeneratedTeam teamB;

  TeamGenerationResult({
    required this.teamA,
    required this.teamB,
  });

  double get averageDifference =>
      (teamA.averageRating - teamB.averageRating).abs();
}