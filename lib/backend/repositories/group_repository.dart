import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../services/group_management_service.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GroupManagementService _groupService = GroupManagementService();

  Future<Group> createGroup({
    required String name,
    required String description,
    required String sportType,
    required String creatorUserId,
    required String creatorDisplayName,
    List<Map<String, String>> additionalMembers = const [],
  }) async {
    final groupRef = _firestore.collection('groups').doc();
    final now = DateTime.now();

    final allMemberIds = [creatorUserId, ...additionalMembers.map((m) => m['uid']!)];

    final group = _groupService.createGroup(
      id: groupRef.id,
      name: name,
      description: description,
      sportType: sportType,
      createdAt: now,
      memberIds: allMemberIds,
    );

    final initialAdmin = _groupService.createInitialAdminMembership(
      userId: creatorUserId,
      groupId: groupRef.id,
      displayName: creatorDisplayName,
      joinedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(groupRef, group.toMap());
    batch.set(
      groupRef.collection('members').doc(creatorUserId),
      initialAdmin.toMap(),
    );

    for (var member in additionalMembers) {
      final uid = member['uid']!;
      final displayName = member['displayName'] ?? 'Unknown';
      
      final m = GroupMember(
        userId: uid,
        groupId: groupRef.id,
        role: 'member',
        joinedAt: now,
        displayName: displayName,
      );
      batch.set(
        groupRef.collection('members').doc(uid),
        m.toMap(),
      );
    }

    await batch.commit();
    return group;
  }

  Stream<List<Group>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Group.fromMap(doc.data())).toList());
  }

  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GroupMember.fromMap(doc.data())).toList());
  }
}
