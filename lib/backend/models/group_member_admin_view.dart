class GroupMemberAdminView {
  final String userId;
  final String displayName;
  final String role;
  final bool canPromoteToAdmin;
  final bool canDemoteToMember;
  final bool canRemove;

  GroupMemberAdminView({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.canPromoteToAdmin,
    required this.canDemoteToMember,
    required this.canRemove,
  });
}