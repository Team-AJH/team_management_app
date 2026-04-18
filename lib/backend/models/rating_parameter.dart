class RatingParameter {
  final String id;
  final String name;

  RatingParameter({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory RatingParameter.fromMap(Map<String, dynamic> map) {
    return RatingParameter(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  void validate() {
    if (id.trim().isEmpty) {
      throw Exception('Rating parameter ID is required.');
    }

    if (name.trim().isEmpty) {
      throw Exception('Rating parameter name cannot be empty.');
    }

    if (name.length > 50) {
      throw Exception('Rating parameter name cannot exceed 50 characters.');
    }
  }
}