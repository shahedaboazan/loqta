import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/chat/presentation/pages/chat_page.dart';
import 'package:loqta/features/listings/presentation/pages/listing_details_page.dart';
import 'package:loqta/features/notifications/domain/entities/app_notification.dart';
import 'package:loqta/features/notifications/domain/repositories/notification_repository.dart';
import 'package:loqta/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:loqta/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:loqta/features/notifications/presentation/widgets/notification_tile.dart';

/// Screen 17 — Notifications.
///
/// One screen for the whole history. It shows in-app records read out of
/// Supabase — which is a different thing from push notifications delivered by
/// Firebase Cloud Messaging when the app is backgrounded or closed.
///
/// Tapping a row navigates to an existing screen (Chat or Listing Details) when
/// the record carries a destination. No new screen is invented per type.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsBloc>(
      create: (context) {
        final repository = context.read<NotificationRepository>();
        return NotificationsBloc(
          getNotifications: GetNotificationsUseCase(repository),
          markRead: MarkNotificationReadUseCase(repository),
          markAllRead: MarkAllNotificationsReadUseCase(repository),
          notificationRepository: repository,
        )..add(const NotificationsRequested());
      },
      child: const NotificationsView(),
    );
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoqtaColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const LoqtaAppBar(title: 'Notification'),
            Expanded(
              child: BlocConsumer<NotificationsBloc, NotificationsState>(
                listenWhen: (previous, current) =>
                    current is NotificationsSuccess &&
                    current.liveUpdateError != null &&
                    (previous is! NotificationsSuccess ||
                        previous.liveUpdateError != current.liveUpdateError),
                listener: (context, state) {
                  if (state is NotificationsSuccess &&
                      state.liveUpdateError != null) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(content: Text(state.liveUpdateError!)),
                      );
                  }
                },
                builder: (context, state) => switch (state) {
                  NotificationsInProgress() => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        LoqtaColors.primary,
                      ),
                    ),
                  ),
                  NotificationsFailure(:final message) => _ErrorState(
                    message: message,
                    onRetry: () => context.read<NotificationsBloc>().add(
                      const NotificationsRequested(),
                    ),
                  ),
                  NotificationsSuccess(:final notifications) =>
                    notifications.isEmpty
                        ? const _EmptyNotifications()
                        : _NotificationList(notifications: notifications),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((item) => item.isUnread).length;

    // Group by calendar day so the date separators in the approved design line
    // up with the rows underneath them.
    final grouped = <DateTime, List<AppNotification>>{};
    for (final notification in notifications) {
      final time = notification.createdAt.toLocal();
      final day = DateTime(time.year, time.month, time.day);
      grouped.putIfAbsent(day, () => <AppNotification>[]).add(notification);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LoqtaSpacing.gutter,
            0,
            LoqtaSpacing.gutter,
            4,
          ),
          child: Row(
            children: [
              // Expanded so the title gives way instead of the row overflowing:
              // a long label or a large text scale must not push the
              // "Mark all read" action off the edge.
              const Expanded(
                child: Text(
                  'All Notification',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LoqtaColors.headingPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: LoqtaText.family,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => context.read<NotificationsBloc>().add(
                    const NotificationsMarkAllRead(),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: LoqtaColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Mark all read ($unreadCount)'),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: LoqtaColors.primary,
            // Waits for the reload to land, so the indicator does not vanish
            // before the fresh rows have actually arrived.
            onRefresh: () async {
              final bloc = context.read<NotificationsBloc>();
              bloc.add(const NotificationsRefreshed());
              await bloc.stream.first;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                LoqtaSpacing.gutter,
                8,
                LoqtaSpacing.gutter,
                24,
              ),
              children: [
                for (final entry in grouped.entries) ...[
                  NotificationDayHeader(day: entry.key),
                  for (final notification in entry.value)
                    NotificationTile(
                      notification: notification,
                      onTap: notification.hasDestination
                          ? () => _open(context, notification)
                          : null,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Navigates to an existing screen. Chat wins when the record carries a
  /// conversation, otherwise the associated listing is opened.
  void _open(BuildContext context, AppNotification notification) {
    context.read<NotificationsBloc>().add(NotificationOpened(notification.id));

    final conversationId = notification.conversationId;
    if (conversationId != null && conversationId.isNotEmpty) {
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              // The notification title is not a participant name, so nothing is
              // invented here: ChatPage resolves the real name from the server.
              builder: (_) => ChatPage(conversationId: conversationId),
            ),
          )
          .then((_) {
            if (context.mounted) {
              context.read<NotificationsBloc>().add(
                const NotificationsRequested(),
              );
            }
          });
      return;
    }

    final listingId = notification.listingId;
    if (listingId != null && listingId.isNotEmpty) {
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ListingDetailsPage(listingId: listingId),
            ),
          )
          .then((_) {
            if (context.mounted) {
              context.read<NotificationsBloc>().add(
                const NotificationsRequested(),
              );
            }
          });
    }
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LoqtaSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: LoqtaColors.surfaceMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 32,
                color: LoqtaColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nothing new',
              style: TextStyle(
                color: LoqtaColors.headingPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: LoqtaText.family,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Messages about your listings and reservations will show up here.',
              textAlign: TextAlign.center,
              style: LoqtaText.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LoqtaSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: LoqtaColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: LoqtaText.subtitle,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: LoqtaColors.primary,
                  side: const BorderSide(color: LoqtaColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      LoqtaSpacing.radiusButton,
                    ),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: LoqtaColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: LoqtaText.family,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
