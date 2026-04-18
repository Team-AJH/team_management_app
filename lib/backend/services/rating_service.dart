import '../models/group_rating.dart';
import '../models/player_rating.dart';

class RatingService {
  GroupRating createGroupRatingConfig({
    required String groupId,
    required List parameters,
  }) {
    final config = GroupRating(
      groupId: groupId,
      parameters: List.from(parameters),
    );

    config.validate();
    return config;
  }

  PlayerRating createPlayerRating({
    required String id,
    required String groupId,
    required String playerId,
    required String ratedBy,
    required Map<String, int> parameterScores,
    required DateTime createdAt,
    required GroupRating config,
  }) {
    config.validate();

    final rating = PlayerRating(
      id: id,
      groupId: groupId,
      playerId: playerId,
      ratedBy: ratedBy,
      parameterScores: parameterScores,
      createdAt: createdAt,
    );

    rating.validate();
    _validateAgainstConfig(rating, config);

    return rating;
  }

  double calculateOverallRating(PlayerRating rating) {
    rating.validate();

    final scores = rating.parameterScores.values.toList();
    final total = scores.fold<int>(0, (sum, score) => sum + score);

    return total / scores.length;
  }

  double calculateAverageOverallFromRatings(List<PlayerRating> ratings) {
    if (ratings.isEmpty) {
      throw Exception('At least one rating is required.');
    }

    final totals = ratings.map(calculateOverallRating).toList();
    final sum = totals.fold<double>(0, (a, b) => a + b);

    return sum / totals.length;
  }

  void _validateAgainstConfig(
    PlayerRating rating,
    GroupRating config,
  ) {
    if (rating.groupId != config.groupId) {
      throw Exception('Rating group does not match config group.');
    }

    final configParameterIds = config.parameters.map((p) => p.id).toSet();
    final ratingParameterIds = rating.parameterScores.keys.toSet();

    if (configParameterIds.length != ratingParameterIds.length) {
      throw Exception(
        'Rating must include exactly the group’s configured parameters.',
      );
    }

    if (!configParameterIds.containsAll(ratingParameterIds)) {
      throw Exception(
        'Rating contains invalid or missing parameters for this group.',
      );
    }
  }
}