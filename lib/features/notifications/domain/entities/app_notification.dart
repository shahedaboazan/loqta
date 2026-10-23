import 'package:equatable/equatable.dart';

/// The notification categories the Notifications screen renders.
///
/// A single screen and a single list cover every type: the Notifications design
/// is one chronological history, not one screen per category.
enum NotificationType {
  newMessage('new_message', 'New message'),
  reservationRequested('reservation_requested', 'Reservation request'),
  reservationAccepted('reservation_accepted', 'Reservation accepted'),
  listingStatusUpdate('listing_status_update', 'Listing status update'),
  transactionCompleted('transaction_completed', 'Transaction completed'),
  ratingReceived('rating_received', 'Rating received'),
  reportAccountUpdate('report_account_update', 'Report / account update');

  const NotificationType(this.wireValue, this.label);

  /// The value stored in `public.notifications.type`.
  final String wireValue;

  /// Human label used when the stored row has no title.
  final String label;

  static NotificationType fromWire(String? value) => values.firstWhere(
    (type) => type.wireValue == value,
    orElse: () => NotificationType.listingStatusUpdate,
  );
}

/// An in-app notification record.
///
/// Distinct from a push notification: this is the row the Notifications screen
/// reads out of Supabase. Push delivery is handled separately and server-side.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.listingId,
    this.conversationId,
    this.readAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;

  /// Optional destinations. Null when the notification has nothing to open, in
  /// which case the row is not tappable.
  final String? listingId;
  final String? conversationId;

  final DateTime? readAt;

  bool get isRead => readAt != null;

  bool get isUnread => readAt == null;

  /// True when tapping the row should navigate somewhere that already exists.
  bool get hasDestination => conversationId != null || listingId != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    userId: userId,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    listingId: listingId,
    conversationId: conversationId,
    readAt: readAt ?? this.readAt,
  );

  @override
  List<Object?> get props => [id, readAt, title, body];
}
