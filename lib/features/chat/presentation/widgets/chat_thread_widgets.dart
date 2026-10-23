import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';

/// The safety notice the approved design shows at the top of every thread.
///
/// It is fixed product copy, not a message: it is rendered from this widget and
/// never enters the message list, so it can never be mistaken for something the
/// other participant wrote.
class ChatSafetyNotice extends StatelessWidget {
  const ChatSafetyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        10,
        LoqtaSpacing.gutter,
        6,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LoqtaColors.surfaceMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3EEDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 15,
            color: LoqtaColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Agree on pickup times and inspect items before finalizing '
              'exchange.',
              style: const TextStyle(
                color: LoqtaColors.primary,
                fontSize: 10.5,
                height: 1.35,
                fontFamily: LoqtaText.family,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Today, May 14" separator between days of messages.
class ChatDaySeparator extends StatelessWidget {
  const ChatDaySeparator(this.day, {super.key});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: LoqtaColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: LoqtaColors.border),
          ),
          child: Text(
            label(day),
            style: const TextStyle(
              color: LoqtaColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: LoqtaText.family,
            ),
          ),
        ),
      ),
    );
  }

  /// "Today", "Yesterday", then a date.
  static String label(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final midnight = DateTime(day.year, day.month, day.day);
    final difference = today.difference(midnight).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${day.day} ${months[day.month - 1]}, ${day.year}';
  }
}

/// The pickup bar above the composer: "Pickup only · Damascus · Mazzeh".
///
/// Only the public location is ever shown. The exact pickup address is never
/// available to this screen, so there is nothing to leak here.
class ChatPickupBar extends StatelessWidget {
  const ChatPickupBar({super.key, required this.locationLabel});

  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (locationLabel.trim().isNotEmpty) locationLabel.trim(),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        8,
        LoqtaSpacing.gutter,
        8,
      ),
      color: LoqtaColors.background,
      child: Row(
        children: [
          const Icon(
            Icons.place_outlined,
            size: 13,
            color: LoqtaColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              // Every Loqta exchange is a pickup: the schema has no delivery
              // option, so this states the product rule rather than a value.
              ['Pickup only', ...parts].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LoqtaColors.textSecondary,
                fontSize: 10.5,
                fontFamily: LoqtaText.family,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
