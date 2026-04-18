import 'event_admin_view.dart';

class EventAdminSummaryView extends EventAdminView {
  final int totalParticipants;
  final int totalPaid;
  final int totalUnpaid;
  final int totalStandby;
  final int projectedFinalCount;

  EventAdminSummaryView({
    required super.eventId,
    required super.title,
    required super.description,
    required super.location,
    required super.eventDate,
    required super.maxPlayers,
    required super.status,
    required super.billingMonth,
    required super.canEdit,
    required super.canCancel,
    required super.canComplete,
    required this.totalParticipants,
    required this.totalPaid,
    required this.totalUnpaid,
    required this.totalStandby,
    required this.projectedFinalCount,
  });
}