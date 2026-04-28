import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Announcement>> getAnnouncementsForGroup(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Announcement.fromMap(doc.data()))
              .toList(),
        );
  }
}
