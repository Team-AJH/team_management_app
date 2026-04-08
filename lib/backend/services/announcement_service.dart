import '../models/announcement.dart';
import '../models/group_member.dart';
import 'group_permissions_service.dart';

class AnnouncementService {
  final GroupPermissionsService _permissionsService =
      GroupPermissionsService();

  Announcement createAnnouncement({
    required GroupMember member,
    required String id,
    required String groupId,
    required String title,
    required String content,
    required DateTime createdAt,
  }) {
    _permissionsService.enforceCanPostAnnouncement(member);

    final announcement = Announcement(
      id: id,
      groupId: groupId,
      title: title,
      content: content,
      createdBy: member.userId,
      createdByName: member.displayName,
      createdAt: createdAt,
    );

    announcement.validate();

    return announcement;
  }
}