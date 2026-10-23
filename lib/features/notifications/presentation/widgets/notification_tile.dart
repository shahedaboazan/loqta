import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/notifications/domain/entities/app_notification.dart';

/// One notification row: category glyph, title, body, timestamp and an unread
/// marker.
///
/// Rows with a destination are tappable; rows without one are not, so the
/// interface never offers a tap that leads nowhere.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(notification.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: notification.isUnread
              ? LoqtaColors.surfaceMint.withValues(alpha: 0.55)
              : LoqtaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isUnread
                ? const Color(0xFFD3EEDD)
                : LoqtaColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(notification.type), size: 19, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: LoqtaColors.headingPrimary,
                      fontSize: 13.5,
                      fontWeight: notification.isUnread
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                  if (notification.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: LoqtaText.caption,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: const TextStyle(
                      color: LoqtaColors.textTertiary,
                      fontSize: 9.5,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                ],
              ),
            ),
            if (notification.isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 4),
                decoration: const BoxDecoration(
                  color: LoqtaColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Color _accentFor(NotificationType type) => switch (type) {
    NotificationType.newMessage => LoqtaColors.primary,
    NotificationType.ratingReceived => LoqtaColors.accentCyan,
    _ => LoqtaColors.secondaryGreen,
  };

  static IconData _iconFor(NotificationType type) => switch (type) {
    NotificationType.newMessage => Icons.chat_bubble_outline,
    NotificationType.reservationRequested => Icons.bookmark_border,
    NotificationType.reservationAccepted => Icons.check_circle_outline,
    NotificationType.listingStatusUpdate => Icons.inventory_2_outlined,
    NotificationType.transactionCompleted => Icons.task_alt_outlined,
    NotificationType.ratingReceived => Icons.star_outline,
    NotificationType.reportAccountUpdate => Icons.shield_outlined,
  };

  /// "12:10 pm" today, "Yesterday", or a date, matching the reference.
  static String _formatTimestamp(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final difference = today.difference(day).inDays;

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final clock = '$hour:$minute ${local.hour < 12 ? 'am' : 'pm'}';

    if (difference == 0) return clock;
    if (difference == 1) return 'Yesterday, $clock';

    return '${local.day}/${local.month}/${local.year}, $clock';
  }
}

/// The date separator between groups of notifications, e.g.
/// "Today, April 20" / "Yesterday, April 19".
class NotificationDayHeader extends StatelessWidget {
  const NotificationDayHeader({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;

    final label = switch (difference) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => '${day.day}/${day.month}/${day.year}',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 0, 10),
      child: Text(
        label,
        style: const TextStyle(
          color: LoqtaColors.headingPrimary,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          fontFamily: LoqtaText.family,
        ),
      ),
    );
  }
}
