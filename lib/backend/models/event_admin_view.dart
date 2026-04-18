class EventAdminView {
  final String eventId;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final int maxPlayers;
  final String status;
  final String billingMonth;

  final bool canEdit;
  final bool canCancel;
  final bool canComplete;

  EventAdminView({
    required this.eventId,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.maxPlayers,
    required this.status,
    required this.billingMonth,
    required this.canEdit,
    required this.canCancel,
    required this.canComplete,
  });
}