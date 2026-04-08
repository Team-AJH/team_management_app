// anadir funcion para anadir otros usuarios, como usar el servicio de Member , pensar si admin anade o otros miebros, roles involed?
// compund unique inviteCode can be used to invite people (como el del paymen tracker)


import 'package:team_management_app/backend/models/group.dart';
import 'package:team_management_app/backend/models/app_user.dart';
import 'package:team_management_app/backend/models/member.dart';
import 'package:team_management_app/backend/services/firebase/member_service.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MemberService _memberService = MemberService(); // Handle subcollection correctly

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _db.collection('group');

  // Creates a new group document in the "group" collection.
  Future<void> createGroupDocument(
    String groupId,
    String name,
    String description,
    String adminUid,
  ) async {
    final Group newGroup = Group(
      groupId: groupId,
      name: name,
      description: description,
      adminUid: adminUid,
      createdAt: DateTime.now(),
    );

    await _groupsCollection.doc(groupId).set(newGroup.toMap());

    // Automatically insert the creator into the members subcollection as an Admin!
    await _memberService.createMemberDocumentWithAdminRole(adminUid, groupId);
  }

  // function to invite people, or add other users to the group
  // compound unique inviteCode can be used to invite people (como el del payment tracker)
  /*
  Future<void> addFriend(String userId, String groupId) async {
    await _memberService.createMemberDocumentWithMemberRole(userId, groupId);
  }
  */

  // Retrieves a group document by its group ID.
  Future<Group?> getGroupDocument(String groupId) async {
    final docSnapshot = await _groupsCollection.doc(groupId).get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return Group.fromMap(docSnapshot.data()!, docSnapshot.id);
    }

    return null;
  }

  // Updates an existing group's information.
  Future<void> updateGroupDocument(
    String groupId,
    Map<String, dynamic> dataToUpdate,
  ) async {
    await _groupsCollection.doc(groupId).update(dataToUpdate);
  }

  // Deletes a group document.
  Future<void> deleteGroupDocument(String groupId) async {
    await _groupsCollection.doc(groupId).delete();
  }
}
