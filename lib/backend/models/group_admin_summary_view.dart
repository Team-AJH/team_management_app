import 'group.dart';
import 'group_member_admin_view.dart';

class GroupAdminSummaryView {
  final String groupId;
  final String groupName;
  final String description;
  final String sportType;
  final int totalMembers;
  final int totalAdmins;
  final List<GroupMemberAdminView> members;

  GroupAdminSummaryView({
    required this.groupId,
    required this.groupName,
    required this.description,
    required this.sportType,
    required this.totalMembers,
    required this.totalAdmins,
    required this.members,
  });

  factory GroupAdminSummaryView.fromGroup({
    required Group group,
    required int totalMembers,
    required int totalAdmins,
    required List<GroupMemberAdminView> members,
  }) {
    return GroupAdminSummaryView(
      groupId: group.id,
      groupName: group.name,
      description: group.description,
      sportType: group.sportType,
      totalMembers: totalMembers,
      totalAdmins: totalAdmins,
      members: members,
    );
  }
}