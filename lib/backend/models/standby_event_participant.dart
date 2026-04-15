class StandbyEventParticipant {
  final String eventId;
  final String userId;
  final String displayName;
  final DateTime joinedStandbyAt;

  StandbyEventParticipant({
    required this.eventId,
    required this.userId,
    required this.displayName,
    required this.joinedStandbyAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'displayName': displayName,
      'joinedStandbyAt': joinedStandbyAt.toIso8601String(),
    };
  }

  factory StandbyEventParticipant.fromMap(Map<String, dynamic> map) {
    return StandbyEventParticipant(
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      joinedStandbyAt: DateTime.parse(map['joinedStandbyAt']),
    );
  }

  void validate() {
    if (eventId.trim().isEmpty) {
      throw Exception('Event ID is required.');
    }

    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    if (displayName.trim().isEmpty) {
      throw Exception('Display name is required.');
    }
  }
}