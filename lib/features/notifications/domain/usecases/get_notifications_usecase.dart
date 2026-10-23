import 'package:loqta/features/notifications/domain/entities/app_notification.dart';
import 'package:loqta/features/notifications/domain/repositories/notification_repository.dart';

/// Loads the signed-in user's notification history.
class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<List<AppNotification>> call() => _repository.fetchNotifications();
}

/// Marks one notification read.
///
/// The database scopes the update to `auth.uid()`, so this can only ever touch
/// the caller's own rows.
class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call(String notificationId) =>
      _repository.markRead(notificationId);
}

/// Clears the unread badge across the whole history.
class MarkAllNotificationsReadUseCase {
  const MarkAllNotificationsReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call() => _repository.markAllRead();
}
