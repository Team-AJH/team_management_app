class RatedPlayer {
  final String userId;
  final String displayName;
  final double overallRating;

  RatedPlayer({
    required this.userId,
    required this.displayName,
    required this.overallRating,
  });

  void validate() {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    if (displayName.trim().isEmpty) {
      throw Exception('Display name is required.');
    }

    if (overallRating < 1 || overallRating > 10) {
      throw Exception('Overall rating must be between 1 and 10.');
    }
  }
}