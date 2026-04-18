import '../models/event.dart';
import '../models/group_member.dart';
import '../models/event_admin_view.dart';
import '../models/event_admin_summary_view.dart';
import '../models/event_participant.dart';
import '../models/standby_event_participant.dart';
import '../models/payment_tracker.dart';
import 'group_permissions_service.dart';

class EventService {
  final GroupPermissionsService _permissionsService =
      GroupPermissionsService();

  Event createEvent({
    required GroupMember actingMember,
    required String id,
    required String groupId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required DateTime createdAt,
    required int maxPlayers,
    required String billingMonth,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    final event = Event(
      id: id,
      groupId: groupId,
      title: title,
      description: description,
      location: location,
      eventDate: eventDate,
      createdBy: actingMember.userId,
      createdAt: createdAt,
      maxPlayers: maxPlayers,
      status: 'scheduled',
      billingMonth: billingMonth,
    );

    event.validate();
    return event;
  }

  Event updateEvent({
    required GroupMember actingMember,
    required Event existingEvent,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required int maxPlayers,
    required String billingMonth,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    if (existingEvent.status == 'completed') {
      throw Exception('Completed events cannot be edited.');
    }

    if (existingEvent.status == 'cancelled') {
      throw Exception('Cancelled events cannot be edited.');
    }

    final updatedEvent = Event(
      id: existingEvent.id,
      groupId: existingEvent.groupId,
      title: title,
      description: description,
      location: location,
      eventDate: eventDate,
      createdBy: existingEvent.createdBy,
      createdAt: existingEvent.createdAt,
      maxPlayers: maxPlayers,
      status: existingEvent.status,
      billingMonth: billingMonth,
    );

    updatedEvent.validate();
    return updatedEvent;
  }

  Event cancelEvent({
    required GroupMember actingMember,
    required Event existingEvent,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    if (existingEvent.status == 'completed') {
      throw Exception('Completed events cannot be cancelled.');
    }

    if (existingEvent.status == 'cancelled') {
      throw Exception('Event is already cancelled.');
    }

    final cancelledEvent = Event(
      id: existingEvent.id,
      groupId: existingEvent.groupId,
      title: existingEvent.title,
      description: existingEvent.description,
      location: existingEvent.location,
      eventDate: existingEvent.eventDate,
      createdBy: existingEvent.createdBy,
      createdAt: existingEvent.createdAt,
      maxPlayers: existingEvent.maxPlayers,
      status: 'cancelled',
      billingMonth: existingEvent.billingMonth,
    );

    cancelledEvent.validate();
    return cancelledEvent;
  }

  Event completeEvent({
    required GroupMember actingMember,
    required Event existingEvent,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    if (existingEvent.status == 'cancelled') {
      throw Exception('Cancelled events cannot be marked as completed.');
    }

    if (existingEvent.status == 'completed') {
      throw Exception('Event is already completed.');
    }

    final completedEvent = Event(
      id: existingEvent.id,
      groupId: existingEvent.groupId,
      title: existingEvent.title,
      description: existingEvent.description,
      location: existingEvent.location,
      eventDate: existingEvent.eventDate,
      createdBy: existingEvent.createdBy,
      createdAt: existingEvent.createdAt,
      maxPlayers: existingEvent.maxPlayers,
      status: 'completed',
      billingMonth: existingEvent.billingMonth,
    );

    completedEvent.validate();
    return completedEvent;
  }

  List<EventAdminView> buildEventAdminViews({
    required GroupMember actingMember,
    required List<Event> events,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    return events.map((event) {
      final isCompleted = event.status == 'completed';
      final isCancelled = event.status == 'cancelled';

      return EventAdminView(
        eventId: event.id,
        title: event.title,
        description: event.description,
        location: event.location,
        eventDate: event.eventDate,
        maxPlayers: event.maxPlayers,
        status: event.status,
        billingMonth: event.billingMonth,
        canEdit: !isCompleted && !isCancelled,
        canCancel: !isCompleted && !isCancelled,
        canComplete: !isCompleted && !isCancelled,
      );
    }).toList();
  }

  EventParticipant joinEvent({
    required GroupMember member,
    required Event event,
    required String participantId,
    required DateTime joinedAt,
    required List<EventParticipant> currentParticipants,
  }) {
    if (!member.isMember()) {
      throw Exception('Only group members can join events.');
    }

    if (event.status != 'scheduled') {
      throw Exception('Cannot join a non-active event.');
    }

    final alreadyJoined = currentParticipants.any(
      (p) => p.userId == member.userId,
    );

    if (alreadyJoined) {
      throw Exception('User already joined this event.');
    }

    final participant = EventParticipant(
      id: participantId,
      eventId: event.id,
      userId: member.userId,
      displayName: member.displayName,
      joinedAt: joinedAt,
    );

    participant.validate();
    return participant;
  }

  void leaveEvent({
    required GroupMember member,
    required EventParticipant participant,
  }) {
    if (member.userId != participant.userId) {
      throw Exception('Users can only leave their own participation.');
    }
  }

  StandbyEventParticipant joinStandbyList({
    required GroupMember member,
    required Event event,
    required List<EventParticipant> currentParticipants,
    required List<StandbyEventParticipant> currentStandby,
    required DateTime joinedStandbyAt,
  }) {
    if (!member.isMember()) {
      throw Exception('Only group members can join the standby list.');
    }

    if (event.status != 'scheduled') {
      throw Exception('Cannot join standby for a non-active event.');
    }

    final alreadyParticipant = currentParticipants.any(
      (p) => p.userId == member.userId,
    );

    if (alreadyParticipant) {
      throw Exception('User is already on the event list.');
    }

    final alreadyStandby = currentStandby.any(
      (p) => p.userId == member.userId,
    );

    if (alreadyStandby) {
      throw Exception('User is already on the standby list.');
    }

    final standbyParticipant = StandbyEventParticipant(
      eventId: event.id,
      userId: member.userId,
      displayName: member.displayName,
      joinedStandbyAt: joinedStandbyAt,
    );

    standbyParticipant.validate();
    return standbyParticipant;
  }

  bool isParticipantCoveredForEvent({
    required Event event,
    required String userId,
    required List<PaymentTracker> trackers,
  }) {
    return trackers.any(
      (tracker) =>
          tracker.userUid == userId &&
          tracker.groupId == event.groupId &&
          tracker.billingMonth == event.billingMonth &&
          tracker.paymentStatus == PaymentStatus.verified,
    );
  }

  List<EventParticipant> buildPaidList({
    required Event event,
    required List<EventParticipant> participants,
    required List<PaymentTracker> trackers,
  }) {
    return participants.where((participant) {
      return isParticipantCoveredForEvent(
        event: event,
        userId: participant.userId,
        trackers: trackers,
      );
    }).toList();
  }

  List<EventParticipant> buildUnpaidList({
    required Event event,
    required List<EventParticipant> participants,
    required List<PaymentTracker> trackers,
  }) {
    return participants.where((participant) {
      return !isParticipantCoveredForEvent(
        event: event,
        userId: participant.userId,
        trackers: trackers,
      );
    }).toList();
  }

  List<EventParticipant> buildFinalParticipantList({
    required Event event,
    required List<EventParticipant> participants,
    required List<PaymentTracker> trackers,
    required List<StandbyEventParticipant> standbyParticipants,
    required DateTime currentTime,
  }) {
    final paidList = buildPaidList(
      event: event,
      participants: participants,
      trackers: trackers,
    );

    final cutoffTime = event.eventDate.subtract(const Duration(hours: 1));

    if (currentTime.isBefore(cutoffTime)) {
      return paidList;
    }

    final availableSpots = event.maxPlayers - paidList.length;

    if (availableSpots <= 0) {
      return paidList;
    }

    final sortedStandby = [...standbyParticipants]
      ..sort((a, b) => a.joinedStandbyAt.compareTo(b.joinedStandbyAt));

    final promotedStandby = sortedStandby.take(availableSpots).map((standby) {
      return EventParticipant(
        id: 'promoted_${standby.userId}_${event.id}',
        eventId: standby.eventId,
        userId: standby.userId,
        displayName: standby.displayName,
        joinedAt: standby.joinedStandbyAt,
      );
    }).toList();

    return [...paidList, ...promotedStandby];
  }

  EventAdminSummaryView buildEventAdminSummary({
    required GroupMember actingMember,
    required Event event,
    required List<EventParticipant> participants,
    required List<PaymentTracker> trackers,
    required List<StandbyEventParticipant> standbyParticipants,
    required DateTime currentTime,
  }) {
    _permissionsService.enforceCanManageGroup(actingMember);

    final paidList = buildPaidList(
      event: event,
      participants: participants,
      trackers: trackers,
    );

    final unpaidList = buildUnpaidList(
      event: event,
      participants: participants,
      trackers: trackers,
    );

    final finalList = buildFinalParticipantList(
      event: event,
      participants: participants,
      trackers: trackers,
      standbyParticipants: standbyParticipants,
      currentTime: currentTime,
    );

    final isCompleted = event.status == 'completed';
    final isCancelled = event.status == 'cancelled';

    return EventAdminSummaryView(
      eventId: event.id,
      title: event.title,
      description: event.description, //parameter isnt defined
      location: event.location,
      eventDate: event.eventDate,
      maxPlayers: event.maxPlayers,
      status: event.status,
      billingMonth: event.billingMonth, //parameter isnt defined
      canEdit: !isCompleted && !isCancelled,
      canCancel: !isCompleted && !isCancelled,
      canComplete: !isCompleted && !isCancelled, //parameter isnt defined
      totalParticipants: participants.length,
      totalPaid: paidList.length,
      totalUnpaid: unpaidList.length,
      totalStandby: standbyParticipants.length,
      projectedFinalCount: finalList.length,
    );
  }
}