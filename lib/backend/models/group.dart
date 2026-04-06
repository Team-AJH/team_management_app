import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_management_app/backend/models/app_user.dart';
import 'package:team_management_app/backend/models/Event.dart';

const int DEFAULT_PAYMENT_DUE_DATE = -1;

class Group {
  final String groupId;
  final String name;
  final String description;
  final String adminUid;
  final DateTime createdAt;
  final List<AppUser> members;
  final List<Event> events;
  final int paymentDueDate;

  Group({
    required this.groupId,
    required this.name,
    required this.description,
    required this.adminUid,
    required this.createdAt,
    required this.members,
    this.events = const [],
    this.paymentDueDate = DEFAULT_PAYMENT_DUE_DATE,
  });

  // Convert Firestore document to Group object
  factory Group.fromMap(Map<String, dynamic> data, String documentId) {
    return Group(
      groupId: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      adminUid: data['adminUid'] ?? '',
      members: data['members'] ?? [],
      events: data['events'] != null
          ? (data['events'] as List<dynamic>)
                .map((event) => Event.fromMap(event, ''))
                .toList()
          : [],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      paymentDueDate: data['paymentDueDate'] ?? DEFAULT_PAYMENT_DUE_DATE,
    );
  }

  // Convert Group object to Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'adminUid': adminUid,
      'members': members.map((member) => member.toMap()).toList(),
      'events': events.map((event) => event.toMap()).toList(),
      'createdAt': createdAt,
      'paymentDueDate': paymentDueDate,
    };
  }
}
