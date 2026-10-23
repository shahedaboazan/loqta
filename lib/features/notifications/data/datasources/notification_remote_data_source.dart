import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/notifications/data/models/notification_model.dart';
import 'package:loqta/features/notifications/domain/entities/app_notification.dart';

/// Raised when there is no session, so there is nobody to read notifications.
class NotificationsUnavailableException implements Exception {
  const NotificationsUnavailableException();

  @override
  String toString() => 'NotificationsUnavailableException';
}

/// Supabase access to `public.notifications`.
class NotificationRemoteDataSource {
  static const String channel = 'notifications:user';

  SupabaseClient get _client => Supabase.instance.client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const NotificationsUnavailableException();
    return id;
  }

  Future<List<AppNotification>> fetchNotifications() async {
    _currentUserId;
    final rows = await _client
        .from('notifications')
        .select('*')
        // No user_id filter: RLS already restricts the result to the caller, so
        // the client cannot widen it.
        .order('created_at', ascending: false)
        .order('id', ascending: false);

    return NotificationModel.fromRows(rows);
  }

  Future<void> markRead(String notificationId) async {
    final userId = _currentUserId;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  Future<void> markAllRead() async {
    final userId = _currentUserId;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }

  /// Realtime INSERTs for the signed-in user.
  Stream<AppNotification> watchNotifications() {
    final controller = StreamController<AppNotification>();
    RealtimeChannel? realtime;
    var closed = false;

    controller.onListen = () {
      final userId = _currentUserId;
      final current = _client.channel(channel);
      realtime = current;
      current
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            // Realtime payloads are not filtered by RLS, so the listener itself
            // is scoped to this user's id.
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (closed) return;
              final raw = payload.newRecord;
              if (raw.isEmpty) return;
              controller.add(NotificationModel.fromRow(raw));
            },
          )
          .subscribe();
    };

    controller.onCancel = () {
      closed = true;
      final current = realtime;
      realtime = null;
      if (current != null) {
        unawaited(_client.removeChannel(current));
      }
    };

    return controller.stream;
  }
}
