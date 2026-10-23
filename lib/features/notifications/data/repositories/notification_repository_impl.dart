import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:loqta/features/notifications/domain/entities/app_notification.dart';
import 'package:loqta/features/notifications/domain/errors/notification_failure.dart';
import 'package:loqta/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dataSource);

  final NotificationRemoteDataSource _dataSource;

  @override
  Future<List<AppNotification>> fetchNotifications() =>
      _guard(_dataSource.fetchNotifications);

  @override
  Stream<AppNotification> watchNotifications() =>
      _dataSource.watchNotifications();

  @override
  Future<void> markRead(String notificationId) =>
      _guard(() => _dataSource.markRead(notificationId));

  @override
  Future<void> markAllRead() => _guard(_dataSource.markAllRead);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on NotificationFailure {
      rethrow;
    } catch (error) {
      throw NotificationFailure(mapNotificationError(error));
    }
  }
}

String mapNotificationError(Object error) {
  if (error is NotificationFailure) return error.message;

  if (error is NotificationsUnavailableException) {
    return 'Sign in to see your notifications.';
  }

  if (error is PostgrestException) {
    return switch (error.code) {
      '42501' => 'You do not have permission to do that.',
      _ => _clean(error.message),
    };
  }

  if (error is SocketException) {
    return 'Network error. Check your connection and try again.';
  }

  return _clean(error.toString());
}

String _clean(
  String raw, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final message = raw.trim();
  if (message.isEmpty || message.toLowerCase() == 'exception') return fallback;
  return message;
}
