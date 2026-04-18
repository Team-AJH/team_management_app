import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetches users who are in any group the current user belongs to
  Future<List<AppUser>> getKnownUsers(String currentUserId) async {
    // 1. Get all groups this user is a member of
    final groupsQuery = await _firestore
        .collection('groups')
        .where('memberIds', arrayContains: currentUserId)
        .get();

    final Set<String> knownUids = {};
    final List<AppUser> knownUsers = [];

    // 2. Fetch members from all these groups
    for (var groupDoc in groupsQuery.docs) {
      final membersQuery = await _firestore
          .collection('groups')
          .doc(groupDoc.id)
          .collection('members')
          .get();

      for (var memberDoc in membersQuery.docs) {
        final uid = memberDoc.id; // member document ID is typically the uid
        if (uid != currentUserId && !knownUids.contains(uid)) {
          knownUids.add(uid);
          final data = memberDoc.data();
          knownUsers.add(AppUser(
            uid: uid,
            email: data['email'] ?? '', // Email might not be in member doc, but we do our best
            displayName: data['displayName'] ?? 'Unknown User',
            status: 'active',
            createdAt: DateTime.now(), // Fallback if necessary
          ));
        }
      }
    }

    return knownUsers;
  }
}
