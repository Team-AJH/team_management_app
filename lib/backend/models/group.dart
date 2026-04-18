class Group {
  final String id;
  final String name;
  final String description;
  final String sportType;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.sportType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sportType': sportType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      sportType: map['sportType'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  void validate() {
    if (name.trim().isEmpty) {
     throw Exception('Group name cannot be empty.');
    }

    if (description.trim().isEmpty) {
      throw Exception('Group description cannot be empty.');
    }

    if (sportType.trim().isEmpty) {
      throw Exception('Sport type is required.');
    }

    if (name.length > 100) {
      throw Exception('Group name cannot exceed 100 characters.');
    }

    if (description.length > 500) {
      throw Exception('Group description cannot exceed 500 characters.');
    }
  }
}