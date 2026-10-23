import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/notifications/domain/entities/app_notification.dart';
import 'package:loqta/features/notifications/domain/errors/notification_failure.dart';
import 'package:loqta/features/notifications/domain/repositories/notification_repository.dart';
import 'package:loqta/features/notifications/domain/usecases/get_notifications_usecase.dart';

/// Drives the Notifications screen (Screen 17).
///
/// Renders one chronological list for every notification type — there is no
/// per-type screen. Rows arrive through Realtime so the list stays current
/// without a manual refresh.
sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInProgress extends NotificationsState {
  const NotificationsInProgress();
}

class NotificationsSuccess extends NotificationsState {
  const NotificationsSuccess(this.notifications, {this.liveUpdateError});

  final List<AppNotification> notifications;

  /// Set when the Realtime subscription reported a failure. The loaded rows stay
  /// on screen; the screen shows this as a snackbar so a stalled live update is
  /// never silently mistaken for "nothing new".
  final String? liveUpdateError;

  int get unreadCount => notifications.where((item) => item.isUnread).length;

  @override
  List<Object?> get props => [notifications, liveUpdateError];
}

class NotificationsFailure extends NotificationsState {
  const NotificationsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsRequested extends NotificationsEvent {
  const NotificationsRequested();
}

/// Re-reads the history without blanking the list first.
///
/// Used by pull-to-refresh: the rows already on screen stay put while the fresh
/// ones load, so a refresh never flashes an empty screen.
class NotificationsRefreshed extends NotificationsEvent {
  const NotificationsRefreshed();
}

/// Marks one notification read. Called when a row is opened.
class NotificationOpened extends NotificationsEvent {
  const NotificationOpened(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllRead extends NotificationsEvent {
  const NotificationsMarkAllRead();
}

/// Internal event raised by the Realtime subscription.
class NotificationReceived extends NotificationsEvent {
  const NotificationReceived(this.notification);

  final AppNotification notification;

  @override
  List<Object?> get props => [notification];
}

/// Internal event raised when the subscription reports a failure.
class NotificationsStreamFailed extends NotificationsEvent {
  const NotificationsStreamFailed();
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
    required NotificationRepository notificationRepository,
  }) : _getNotifications = getNotifications,
       _markRead = markRead,
       _markAllRead = markAllRead,
       _repository = notificationRepository,
       super(const NotificationsInProgress()) {
    on<NotificationsRequested>(_onRequested);
    on<NotificationsRefreshed>(_onRefreshed);
    on<NotificationOpened>(_onOpened);
    on<NotificationsMarkAllRead>(_onMarkAllRead);
    on<NotificationReceived>(_onReceived);
    on<NotificationsStreamFailed>(_onStreamFailed);
  }

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final NotificationRepository _repository;

  StreamSubscription<AppNotification>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }

  Future<void> _onRequested(
    NotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsInProgress());
    await _load(emit, showLoadingFailure: true);
  }

  /// Reloads without emitting the loading state, so pull-to-refresh keeps the
  /// rows already on screen.
  Future<void> _onRefreshed(
    NotificationsRefreshed event,
    Emitter<NotificationsState> emit,
  ) async {
    await _load(emit, showLoadingFailure: false);
  }

  /// Reads the history and keeps the Realtime subscription open.
  Future<void> _load(
    Emitter<NotificationsState> emit, {
    required bool showLoadingFailure,
  }) async {
    try {
      final notifications = await _getNotifications();
      emit(NotificationsSuccess(notifications));

      await _subscription?.cancel();
      _subscription = _repository.watchNotifications().listen(
        (notification) => add(NotificationReceived(notification)),
        onError: (_) => add(const NotificationsStreamFailed()),
      );
    } on NotificationFailure catch (failure) {
      // A refresh that fails leaves the existing list alone; only a first load
      // has nothing to fall back to.
      if (showLoadingFailure) emit(NotificationsFailure(failure.message));
    } catch (_) {
      if (showLoadingFailure) {
        emit(
          const NotificationsFailure('Your notifications could not be loaded.'),
        );
      }
    }
  }

  /// Marks one notification read, optimistically flipping the row so the
  /// interface reflects the change immediately.
  Future<void> _onOpened(
    NotificationOpened event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsSuccess) return;

    final index = current.notifications.indexWhere(
      (item) => item.id == event.id,
    );
    if (index < 0) return;

    final target = current.notifications[index];
    if (target.isRead) return;

    final updated = [...current.notifications];
    updated[index] = target.copyWith(readAt: DateTime.now());
    emit(NotificationsSuccess(updated));

    try {
      await _markRead(event.id);
    } on NotificationFailure {
      // Re-read so the list matches the database again.
      add(const NotificationsRequested());
    } catch (_) {
      add(const NotificationsRequested());
    }
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsSuccess) return;
    if (current.unreadCount == 0) return;

    final readAt = DateTime.now();
    final updated = current.notifications
        .map((item) => item.isRead ? item : item.copyWith(readAt: readAt))
        .toList();
    emit(NotificationsSuccess(updated));

    try {
      await _markAllRead();
    } catch (_) {
      add(const NotificationsRequested());
    }
  }

  /// Prepends a realtime insert.
  ///
  /// Ids already on screen are ignored, so an event that arrives twice cannot
  /// produce a duplicate row.
  void _onReceived(
    NotificationReceived event,
    Emitter<NotificationsState> emit,
  ) {
    final current = state;
    if (current is! NotificationsSuccess) return;

    final exists = current.notifications.any(
      (item) => item.id == event.notification.id,
    );
    if (exists) return;

    emit(NotificationsSuccess([event.notification, ...current.notifications]));
  }

  void _onStreamFailed(
    NotificationsStreamFailed event,
    Emitter<NotificationsState> emit,
  ) {
    // The loaded list stays on screen, but the stalled subscription is reported
    // rather than left to look like "no new notifications".
    final current = state;
    if (current is! NotificationsSuccess) return;

    emit(
      NotificationsSuccess(
        current.notifications,
        liveUpdateError: 'Live updates paused. Pull down to refresh.',
      ),
    );
  }
}
