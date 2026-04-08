import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_management_app/backend/models/member.dart';

class MemberService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference helper
  CollectionReference<Map<String, dynamic>> getMembersCollection(String groupId) {
    return _db.collection('group').doc(groupId).collection('members');
  }

  // Creates a new member document in the "members" subcollection.
  Future<void> createMemberDocument(
    String userId,
    String groupId,
    Role role,
  ) async {
    final Member newMember = Member(
      userId: userId,
      groupId: groupId,
      role: role,
      joinedAt: DateTime.now(),
    );

    await getMembersCollection(groupId).doc(userId).set(newMember.toMap());
  }

  // Create a member with Admin role
  Future<void> createMemberDocumentWithAdminRole(
    String userId,
    String groupId,
  ) async {
    await createMemberDocument(userId, groupId, Role.admin);
  }

  // Create a member with Member role 
  Future<void> createMemberDocumentWithMemberRole(
    String userId,
    String groupId,
  ) async {
    await createMemberDocument(userId, groupId, Role.member);
  }

  // Create a member with Payment Manager role
  Future<void> createMemberDocumentWithPaymentManagerRole(
    String userId,
    String groupId,
  ) async {
    await createMemberDocument(userId, groupId, Role.paymentManager);
  }

  //create function to retrieve the role of a user in a group
  Future<Role?> getRoleOfUserInGroup(String userId, String groupId) async {
    final docSnapshot = await getMembersCollection(groupId).doc(userId).get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return Member.fromMap(docSnapshot.data()!, docSnapshot.id).role;
    }

    return null;
  }
}
