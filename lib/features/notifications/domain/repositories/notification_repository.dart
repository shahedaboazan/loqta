import 'package:loqta/features/notifications/domain/entities/app_notification.dart';

/// Reads and updates the signed-in user's notification history.
///
/// Rows are only ever touched for the caller: RLS on `public.notifications`
/// scopes every statement to `auth.uid()`, so there is no way to read or mark
/// somebody else's notifications.
abstract class NotificationRepository {
  /// Newest first.
  Future<List<AppNotification>> fetchNotifications();

  /// Realtime INSERTs for the signed-in user, so the screen updates without a
  /// manual pull-to-refresh.
  Stream<AppNotification> watchNotifications();

  Future<void> markRead(String notificationId);

  Future<void> markAllRead();
}
