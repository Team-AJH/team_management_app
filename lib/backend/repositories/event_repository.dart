import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/group_member.dart';
import '../models/event_participant.dart';
import '../services/event_service.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EventService _eventService = EventService();

  Future<void> createEvent({
    required GroupMember actingMember,
    required String groupId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required int maxPlayers,
    required String billingMonth,
  }) async {
    final docRef = _firestore.collection('groups').doc(groupId).collection('events').doc();

    final event = _eventService.createEvent(
      actingMember: actingMember,
      id: docRef.id,
      groupId: groupId,
      title: title,
      description: description,
      location: location,
      eventDate: eventDate,
      createdAt: DateTime.now(),
      maxPlayers: maxPlayers,
      billingMonth: billingMonth,
    );

    await docRef.set(event.toMap());
  }

  Future<void> joinEvent({
    required GroupMember member,
    required Event event,
    required List<EventParticipant> currentParticipants,
  }) async {
    final participantRef = _firestore
        .collection('groups')
        .doc(event.groupId)
        .collection('events')
        .doc(event.id)
        .collection('participants')
        .doc(member.userId);

    final participant = _eventService.joinEvent(
      member: member,
      event: event,
      participantId: participantRef.id,
      joinedAt: DateTime.now(),
      currentParticipants: currentParticipants,
    );

    await participantRef.set(participant.toMap());
  }

  Stream<List<Event>> getEventsForGroup(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList());
  }

  Stream<List<EventParticipant>> getEventParticipants(String groupId, String eventId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => EventParticipant.fromMap(doc.data())).toList());
  }
}
