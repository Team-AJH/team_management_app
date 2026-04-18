class PlayerRating {
  final String id;
  final String groupId;
  final String playerId;
  final String ratedBy;
  final Map<String, int> parameterScores;
  final DateTime createdAt;

  PlayerRating({
    required this.id,
    required this.groupId,
    required this.playerId,
    required this.ratedBy,
    required this.parameterScores,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'playerId': playerId,
      'ratedBy': ratedBy,
      'parameterScores': parameterScores,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlayerRating.fromMap(Map<String, dynamic> map) {
    final rawScores =
        Map<String, dynamic>.from(map['parameterScores'] ?? const {});

    return PlayerRating(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      playerId: map['playerId'] ?? '',
      ratedBy: map['ratedBy'] ?? '',
      parameterScores: rawScores.map(
        (key, value) => MapEntry(key, value as int),
      ),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  void validate() {
    if (id.trim().isEmpty) {
      throw Exception('Rating ID is required.');
    }

    if (groupId.trim().isEmpty) {
      throw Exception('Group ID is required.');
    }

    if (playerId.trim().isEmpty) {
      throw Exception('Player ID is required.');
    }

    if (ratedBy.trim().isEmpty) {
      throw Exception('Rater ID is required.');
    }

    if (parameterScores.isEmpty) {
      throw Exception('At least one parameter score is required.');
    }

    for (final entry in parameterScores.entries) {
      if (entry.key.trim().isEmpty) {
        throw Exception('Parameter ID cannot be empty.');
      }

      if (entry.value < 1 || entry.value > 10) {
        throw Exception(
          'Each parameter score must be between 1 and 10.',
        );
      }
    }
  }
}