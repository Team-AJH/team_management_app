import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_management_app/backend/models/group.dart';
import 'package:team_management_app/backend/models/app_user.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _db.collection('group');

  // Creates a new group document in the "group" collection.
  Future<void> createGroupDocument(
    String groupId,
    String name,
    String description,
    String adminUid,
    List<AppUser> members,
  ) async {
    final Group newGroup = Group(
      groupId: groupId,
      name: name,
      description: description,
      adminUid: adminUid,
      members: members,
      createdAt: DateTime.now(),
    );

    await _groupsCollection.doc(groupId).set(newGroup.toMap());
  }

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
