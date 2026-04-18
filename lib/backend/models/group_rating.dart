import 'rating_parameter.dart';

class GroupRating {
  final String groupId;
  final List<RatingParameter> parameters;

  GroupRating({
    required this.groupId,
    required this.parameters,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'parameters': parameters.map((p) => p.toMap()).toList(),
    };
  }

  factory GroupRating.fromMap(Map<String, dynamic> map) {
    final rawParameters = (map['parameters'] as List<dynamic>? ?? []);

    return GroupRating(
      groupId: map['groupId'] ?? '',
      parameters: rawParameters
          .map((p) => RatingParameter.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
    );
  }

  void validate() {
    if (groupId.trim().isEmpty) {
      throw Exception('Group ID is required.');
    }

    if (parameters.isEmpty) {
      throw Exception('A group must have at least 1 rating parameter.');
    }

    if (parameters.length > 10) {
      throw Exception('A group cannot have more than 10 rating parameters.');
    }

    final ids = <String>{};
    final names = <String>{};

    for (final parameter in parameters) {
      parameter.validate();

      if (!ids.add(parameter.id)) {
        throw Exception('Duplicate rating parameter ID: ${parameter.id}');
      }

      final normalizedName = parameter.name.trim().toLowerCase();
      if (!names.add(normalizedName)) {
        throw Exception('Duplicate rating parameter name: ${parameter.name}');
      }
    }
  }
}