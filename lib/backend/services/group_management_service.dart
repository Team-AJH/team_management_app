import '../models/group.dart';
import '../models/group_member.dart';
import '../models/group_member_admin_view.dart';
import '../models/group_admin_summary_view.dart';
import 'group_permissions_service.dart';

class GroupManagementService {
  final GroupPermissionsService _permissionsService =
      GroupPermissionsService();

  Group createGroup({
    required String id,
    required String name,
    required String description,
    required String sportType,
    required DateTime createdAt,
    required List<String> memberIds,
  }) {
    final group = Group(
      id: id,
      name: name,
      description: description,
      sportType: sportType,
      createdAt: createdAt,
      memberIds: memberIds,
    );

    group.validate();
    return group;
  }

  Group updateGroup({
    required GroupMember actingMember,
    required Group existingGroup,
    required String name,
    required String description,
    required String sportType,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    final updatedGroup = Group(
      id: existingGroup.id,
      name: name,
      description: description,
      sportType: sportType,
      createdAt: existingGroup.createdAt,
      memberIds: existingGroup.memberIds,
    );

    updatedGroup.validate();
    return updatedGroup;
  }

  GroupMember createInitialAdminMembership({
    required String userId,
    required String groupId,
    required String displayName,
    required DateTime joinedAt,
  }) {
    final member = GroupMember(
      userId: userId,
      groupId: groupId,
      displayName: displayName,
      role: 'admin',
      joinedAt: joinedAt,
    );

    member.validate();
    return member;
  }

  GroupMember addMember({
    required GroupMember actingMember,
    required String userId,
    required String groupId,
    required String displayName,
    required DateTime joinedAt,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    final member = GroupMember(
      userId: userId,
      groupId: groupId,
      displayName: displayName,
      role: 'member',
      joinedAt: joinedAt,
    );

    member.validate();
    return member;
  }

  GroupMember promoteToAdmin({
    required GroupMember actingMember,
    required GroupMember targetMember,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    final updatedMember = GroupMember(
      userId: targetMember.userId,
      groupId: targetMember.groupId,
      displayName: targetMember.displayName,
      role: 'admin',
      joinedAt: targetMember.joinedAt,
    );

    updatedMember.validate();
    return updatedMember;
  }

  GroupMember demoteToMember({
    required GroupMember actingMember,
    required GroupMember targetMember,
    required List<GroupMember> currentAdmins,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    if (!targetMember.isAdmin()) {
      throw Exception('Target user is not an admin.');
    }

    if (currentAdmins.length <= 1 &&
        currentAdmins.any((admin) => admin.userId == targetMember.userId)) {
      throw Exception('A group must have at least one admin.');
    }

    final updatedMember = GroupMember(
      userId: targetMember.userId,
      groupId: targetMember.groupId,
      displayName: targetMember.displayName,
      role: 'member',
      joinedAt: targetMember.joinedAt,
    );

    updatedMember.validate();
    return updatedMember;
  }

  void removeMember({
    required GroupMember actingMember,
    required GroupMember targetMember,
    required List<GroupMember> currentAdmins,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    if (targetMember.isAdmin() &&
        currentAdmins.length <= 1 &&
        currentAdmins.any((admin) => admin.userId == targetMember.userId)) {
      throw Exception('Cannot remove the last admin from the group.');
    }
  }

  List<GroupMember> getAdmins(List<GroupMember> members) {
    return members.where((member) => member.isAdmin()).toList();
  }

  List<GroupMember> getRegularMembers(List<GroupMember> members) {
    return members.where((member) => member.role == 'member').toList();
  }

  List<GroupMemberAdminView> buildMemberAdminViews({
    required GroupMember actingMember,
    required List<GroupMember> members,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    final admins = getAdmins(members);

    return members.map((member) {
      final isSelf = member.userId == actingMember.userId;
      final isAdmin = member.isAdmin();
      final isLastAdmin =
          isAdmin && admins.length == 1 && admins.first.userId == member.userId;

      return GroupMemberAdminView(
        userId: member.userId,
        displayName: member.displayName,
        role: member.role,
        canPromoteToAdmin: !isAdmin,
        canDemoteToMember: isAdmin && !isLastAdmin,
        canRemove: !isLastAdmin && !isSelf,
      );
    }).toList();
  }

  GroupAdminSummaryView buildGroupAdminSummary({
    required GroupMember actingMember,
    required Group group,
    required List<GroupMember> members,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    final memberViews = buildMemberAdminViews(
      actingMember: actingMember,
      members: members,
    );

    final admins = getAdmins(members);

    return GroupAdminSummaryView.fromGroup(
      group: group,
      totalMembers: members.length,
      totalAdmins: admins.length,
      members: memberViews,
    );
  }
}