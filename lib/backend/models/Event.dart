enum EventStatus { Canceled, Completed, Scheduled }

class Event {
  final String eventId;
  final String groupId;
  final String name;
  final String description;
  final DateTime date;
  final String monthKey;
  final String location;
  final DateTime createdAt;
  final List<String> team1;
  final List<String> team2;
  final EventStatus eventStatus;

  Event({
    required this.eventId,
    required this.groupId,
    required this.name,
    required this.description,
    required this.date,
    required this.monthKey,
    required this.location,
    required this.createdAt,
    this.team1 = const [],
    this.team2 = const [],
    required this.eventStatus,
  });
  //chekear "error" en el toMap
  // convert from firestore document to Event object
  factory Event.fromMap(Map<String, dynamic> data, String documentId) {
    return Event(
      eventId: documentId,
      groupId: data['groupId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] != null
          ? (data['date'] as dynamic).toDate()
          : DateTime.now(),
      monthKey: data['monthKey'] ?? '',
      location: data['location'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      team1: data['team1'] != null ? List<String>.from(data['team1']) : [],
      team2: data['team2'] != null ? List<String>.from(data['team2']) : [],
      eventStatus: data['eventStatus'] != null
          ? EventStatus.values.firstWhere(
              (e) => e.name == data['eventStatus'],
              orElse: () => EventStatus.Scheduled,
            )
          : EventStatus.Scheduled,
    );
  }

  // convert Event object to firestore document map
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'date': date,
      'location': location,
      'monthKey': monthKey,
      'createdAt': createdAt,
      'team1': team1,
      'team2': team2,
      'eventStatus': eventStatus.name,
    };
  }
}
