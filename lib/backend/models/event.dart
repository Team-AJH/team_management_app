class Event {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final String createdBy;
  final DateTime createdAt;
  final int maxPlayers;
  final String status;
  final String billingMonth;

  Event({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.createdBy,
    required this.createdAt,
    required this.maxPlayers,
    required this.status,
    required this.billingMonth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'location': location,
      'eventDate': eventDate.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'maxPlayers': maxPlayers,
      'status': status,
      'billingMonth': billingMonth,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      eventDate: DateTime.parse(map['eventDate']),
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      maxPlayers: map['maxPlayers'] ?? 0,
      status: map['status'] ?? 'scheduled',
      billingMonth: map['billingMonth'] ?? '',
    );
  }

  void validate() {
    if (groupId.trim().isEmpty) {
      throw Exception('Group ID is required.');
    }

    if (title.trim().isEmpty) {
      throw Exception('Event title cannot be empty.');
    }

    if (description.trim().isEmpty) {
      throw Exception('Event description cannot be empty.');
    }

    if (location.trim().isEmpty) {
      throw Exception('Event location cannot be empty.');
    }

    if (createdBy.trim().isEmpty) {
      throw Exception('Creator ID is required.');
    }

    if (title.length > 100) {
      throw Exception('Event title cannot exceed 100 characters.');
    }

    if (description.length > 500) {
      throw Exception('Event description cannot exceed 500 characters.');
    }

    if (location.length > 200) {
      throw Exception('Event location cannot exceed 200 characters.');
    }

    if (maxPlayers <= 0) {
      throw Exception('Max players must be greater than 0.');
    }

    if (status != 'scheduled' &&
        status != 'cancelled' &&
        status != 'completed') {
      throw Exception('Invalid event status.');
    }

    if (billingMonth.trim().isEmpty) {
      throw Exception('Billing month is required.');
    }
  }
}