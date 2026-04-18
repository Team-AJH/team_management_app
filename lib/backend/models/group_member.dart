class GroupMember {
  final String userId;
  final String groupId;
  final String displayName;
  final String role;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.groupId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'groupId': groupId,
      'displayName': displayName,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] ?? '',
      groupId: map['groupId'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'member',
      joinedAt: DateTime.parse(map['joinedAt']),
    );
  }

  void validate() {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    if (groupId.trim().isEmpty) {
      throw Exception('Group ID is required.');
    }

    if (displayName.trim().isEmpty) {
      throw Exception('Display name is required.');
    }

    if (role != 'admin' && role != 'member') {
      throw Exception('Role must be either admin or member.');
    }
  }

  bool isAdmin() => role.toLowerCase() == 'admin';

  bool isMember() => role.toLowerCase() == 'member' || role.toLowerCase() == 'admin';
}