class EventParticipant {
  final String id;
  final String eventId;
  final String userId;
  final String displayName;
  final DateTime joinedAt;

  EventParticipant({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.displayName,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'displayName': displayName,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory EventParticipant.fromMap(Map<String, dynamic> map) {
    return EventParticipant(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      joinedAt: DateTime.parse(map['joinedAt']),
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