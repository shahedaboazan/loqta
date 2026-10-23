import 'package:equatable/equatable.dart';

/// A single chat message.
///
/// [attachmentPath] is the object key inside the private `chat-attachments`
/// bucket, never raw bytes and never a public URL. [attachmentUrl] is a short-
/// lived signed URL resolved on demand, because the bucket is not public.
class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    required this.isMine,
    // Empty for an image-only message: the `content` column is nullable in the
    // database and the model coalesces a missing value to the empty string.
    this.content = '',
    this.attachmentPath,
    this.attachmentMime,
    this.attachmentUrl,
    this.isUploading = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  /// Whether the signed-in user sent this message, which decides bubble
  /// alignment and colour.
  final bool isMine;

  final String? attachmentPath;
  final String? attachmentMime;

  /// Signed URL for [attachmentPath]. Populated once the upload completes.
  final String? attachmentUrl;

  /// True for the optimistic local bubble shown while an image is uploading.
  final bool isUploading;

  bool get hasAttachment => attachmentPath != null;

  bool get hasText => content.trim().isNotEmpty;

  /// Preview line used by the Chat List.
  String get preview {
    final text = content.trim();
    if (text.isNotEmpty) return text;
    if (hasAttachment) return 'Photo';
    return '';
  }

  Message copyWith({
    String? attachmentPath,
    String? attachmentUrl,
    bool? isUploading,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      createdAt: createdAt,
      isMine: isMine,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentMime: attachmentMime,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  @override
  List<Object?> get props => [id, content, attachmentUrl, isUploading];
}
