import 'package:loqta/features/chat/domain/entities/message.dart';

/// Maps a `messages` row onto [Message].
class MessageModel {
  const MessageModel._();

  static Message fromRow(
    Map<String, dynamic> row, {
    required String? currentUserId,
    String? signedUrl,
  }) {
    final senderId = row['sender_id'] as String? ?? '';
    return Message(
      id: row['id'] as String? ?? '',
      conversationId: row['conversation_id'] as String? ?? '',
      senderId: senderId,
      content: row['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      isMine: currentUserId != null && currentUserId == senderId,
      attachmentPath: row['attachment_path'] as String?,
      attachmentMime: row['attachment_mime'] as String?,
      attachmentUrl: signedUrl,
    );
  }

  static List<Message> fromRows(
    List<dynamic> rows, {
    required String? currentUserId,
  }) {
    final messages = rows
        .whereType<Map>()
        .map(
          (row) => fromRow(
            Map<String, dynamic>.from(row),
            currentUserId: currentUserId,
          ),
        )
        .toList();

    // Stable ascending order: created_at first, then the unique id, so two
    // messages written in the same millisecond keep a fixed relative order
    // between the initial load and the realtime merge.
    messages.sort(_byCreatedAtThenId);
    return messages;
  }

  static int _byCreatedAtThenId(Message a, Message b) {
    final byTime = a.createdAt.compareTo(b.createdAt);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  }
}
