//Logic good, tweaks in attributes 
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
  final int paymentDueDate;

  Group({
    required this.groupId,
    required this.name,
    required this.description,
    required this.adminUid,
    required this.createdAt,
    this.paymentDueDate = DEFAULT_PAYMENT_DUE_DATE,
  });

  // Convert Firestore document to Group object
  factory Group.fromMap(Map<String, dynamic> data, String documentId) {
    return Group(
      groupId: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      adminUid: data['adminUid'] ?? '',
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
      'createdAt': createdAt,
      'paymentDueDate': paymentDueDate,
    };
  }
}
