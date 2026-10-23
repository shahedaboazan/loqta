import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/chat/domain/entities/message.dart';

/// One chat bubble.
///
/// Own messages sit on the right in brand green; the other participant's sit on
/// the left in a neutral surface. An image attachment renders as a tappable
/// thumbnail so the Image Viewer can open from it.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.onImageTap,
    this.showSenderName = false,
    this.senderName,
  });

  final Message message;
  final VoidCallback onImageTap;

  /// True for the first message of a run from the same sender, where the
  /// avatar/name line is shown.
  final bool showSenderName;
  final String? senderName;

  static const double maxBubbleWidth = 268;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 44 : LoqtaSpacing.gutter,
        right: isMine ? LoqtaSpacing.gutter : 44,
        top: 4,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !isMine && senderName != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(
                senderName!,
                style: const TextStyle(
                  color: LoqtaColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: LoqtaText.family,
                ),
              ),
            ),
          ],
          if (message.isUploading)
            _UploadingBubble(isMine: isMine)
          else if (message.hasAttachment)
            _AttachmentBubble(
              message: message,
              isMine: isMine,
              onTap: onImageTap,
            )
          else
            _TextBubble(message: message, isMine: isMine),
          const SizedBox(height: 3),
          _Timestamp(message: message, isMine: isMine),
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: MessageBubble.maxBubbleWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isMine ? LoqtaColors.primary : LoqtaColors.fieldFill,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: isMine ? Colors.white : LoqtaColors.textPrimary,
          fontSize: 13,
          height: 1.4,
          fontFamily: LoqtaText.family,
        ),
      ),
    );
  }
}

class _AttachmentBubble extends StatelessWidget {
  const _AttachmentBubble({
    required this.message,
    required this.isMine,
    required this.onTap,
  });

  final Message message;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = message.attachmentUrl;

    return Container(
      width: MessageBubble.maxBubbleWidth,
      decoration: BoxDecoration(
        color: isMine ? LoqtaColors.primary : LoqtaColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
        border: isMine ? null : Border.all(color: LoqtaColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              height: 176,
              width: double.infinity,
              child: url == null
                  ? _AttachmentError(message: message, isMine: isMine)
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      // A signed URL can expire while the chat stays open; the
                      // bubble falls back to a tappable error rather than
                      // showing a broken frame.
                      errorBuilder: (_, _, _) =>
                          _AttachmentError(message: message, isMine: isMine),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : Container(color: LoqtaColors.fieldFill),
                    ),
            ),
          ),
          if (message.hasText)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMine ? Colors.white : LoqtaColors.textPrimary,
                  fontSize: 12.5,
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

class _AttachmentError extends StatelessWidget {
  const _AttachmentError({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isMine
          ? Colors.white.withValues(alpha: 0.14)
          : LoqtaColors.fieldFill,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: isMine ? Colors.white : LoqtaColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Tap to open',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isMine ? Colors.white : LoqtaColors.textSecondary,
                  fontSize: 10.5,
                  fontFamily: LoqtaText.family,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadingBubble extends StatelessWidget {
  const _UploadingBubble({required this.isMine});

  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isMine ? LoqtaColors.primary : LoqtaColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              valueColor: AlwaysStoppedAnimation<Color>(
                isMine ? Colors.white : LoqtaColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Sending photo...',
            style: TextStyle(
              color: isMine ? Colors.white : LoqtaColors.textSecondary,
              fontSize: 12,
              fontFamily: LoqtaText.family,
            ),
          ),
        ],
      ),
    );
  }
}

class _Timestamp extends StatelessWidget {
  const _Timestamp({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(message.createdAt),
      style: const TextStyle(
        color: LoqtaColors.textTertiary,
        fontSize: 9.5,
        fontFamily: LoqtaText.family,
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${_dayLabel(local)}';
  }

  static String _dayLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final difference = today.difference(day).inDays;

    if (difference == 0) return 'AM';
    if (difference == 1) return 'Yesterday';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }
}
