import 'dart:typed_data';

import 'package:loqta/features/chat/domain/entities/message.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';

/// Sends a plain text message.
class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Message> call({
    required String conversationId,
    required String content,
  }) =>
      _repository.sendMessage(conversationId: conversationId, content: content);
}

/// Uploads an image to Supabase Storage and attaches it to a new message.
///
/// Bytes travel to Storage; only the object path is written to the database row.
class SendImageMessageUseCase {
  const SendImageMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Message?> call({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
    String content = '',
  }) => _repository.sendImageMessage(
    conversationId: conversationId,
    bytes: bytes,
    fileName: fileName,
    content: content,
  );
}

/// Resolves a short-lived signed URL for a private attachment.
class GetAttachmentUrlUseCase {
  const GetAttachmentUrlUseCase(this._repository);

  final ChatRepository _repository;

  Future<String> call(String path) => _repository.signedAttachmentUrl(path);
}
