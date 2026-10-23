import 'package:loqta/features/notifications/domain/entities/app_notification.dart';

class NotificationModel {
  const NotificationModel._();

  static AppNotification fromRow(Map<String, dynamic> row) => AppNotification(
    id: row['id'] as String? ?? '',
    userId: row['user_id'] as String? ?? '',
    type: NotificationType.fromWire(row['type'] as String?),
    title: (row['title'] as String? ?? '').trim().isEmpty
        ? NotificationType.fromWire(row['type'] as String?).label
        : row['title'] as String,
    body: row['body'] as String? ?? '',
    createdAt:
        DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    listingId: row['listing_id'] as String?,
    conversationId: row['conversation_id'] as String?,
    readAt: DateTime.tryParse(row['read_at'] as String? ?? '')?.toLocal(),
  );

  static List<AppNotification> fromRows(List<dynamic> rows) => rows
      .whereType<Map>()
      .map((row) => fromRow(Map<String, dynamic>.from(row)))
      .toList();
}
