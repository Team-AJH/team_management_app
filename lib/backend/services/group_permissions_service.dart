import '../models/group_member.dart';

class GroupPermissionsService {
  bool canPostAnnouncement(GroupMember member) {
    return member.isAdmin();
  }

  bool canSendMessage(GroupMember member) {
    return member.isMember();
  }

  bool canViewAnnouncements(GroupMember member) {
    return member.isMember();
  }

  bool canViewChat(GroupMember member) {
    return member.isMember();
  }

  bool canManageGroup(GroupMember member) {
    return member.isAdmin();
  }

  void enforceCanPostAnnouncement(GroupMember member) {
    if (!canPostAnnouncement(member)) {
      throw Exception('Only admins can post announcements.');
    }
  }

  void enforceCanSendMessage(GroupMember member) {
    if (!canSendMessage(member)) {
      throw Exception('Only group members can send messages.');
    }
  }

  void enforceCanManageGroup(GroupMember member) {
    if (!canManageGroup(member)) {
      throw Exception('Only admins can manage the group.');
    }
  }
}