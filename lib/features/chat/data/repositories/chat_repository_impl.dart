import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/entities/message.dart';
import 'package:loqta/features/chat/domain/errors/chat_failure.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._dataSource);

  final ChatRemoteDataSource _dataSource;

  @override
  Future<Conversation> getOrCreateConversation({
    required String listingId,
    required String listingTitle,
    String? listingImageUrl,
    double? listingPrice,
    bool isDonation = false,
  }) async {
    return _guard(() async {
      final id = await _dataSource.resolveConversationId(listingId);
      // Read back through my_conversations() so the header gets the same
      // resolved fields the Chat List uses, instead of a second ad-hoc shape.
      return _dataSource.fetchConversation(id);
    });
  }

  @override
  Future<List<Conversation>> fetchConversations({String? listingId}) =>
      _guard(() => _dataSource.fetchConversations(listingId: listingId));

  @override
  Future<Conversation> fetchConversation(String conversationId) =>
      _guard(() => _dataSource.fetchConversation(conversationId));

  @override
  Future<List<Message>> fetchMessages(String conversationId) =>
      _guard(() => _dataSource.fetchMessages(conversationId));

  @override
  Stream<Message> watchMessages(String conversationId) =>
      _dataSource.watchMessages(conversationId);

  @override
  Stream<void> watchConversationActivity() =>
      _dataSource.watchConversationActivity();

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) => _guard(
    () => _dataSource.sendMessage(
      conversationId: conversationId,
      content: content,
    ),
  );

  @override
  Future<Message?> sendImageMessage({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
    String content = '',
  }) => _guard(
    () => _dataSource.sendImageMessage(
      conversationId: conversationId,
      bytes: bytes,
      fileName: fileName,
      content: content,
    ),
  );

  @override
  Future<void> markRead(String conversationId) =>
      _guard(() => _dataSource.markRead(conversationId));

  @override
  Future<String> signedAttachmentUrl(String path) =>
      _guard(() => _dataSource.signedAttachmentUrl(path));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ChatFailure {
      rethrow;
    } catch (error) {
      throw ChatFailure(mapChatError(error));
    }
  }
}

/// Translates chat-layer errors into copy the screens can show directly.
String mapChatError(Object error) {
  if (error is ChatFailure) return error.message;

  if (error is ChatUnavailableException) {
    return 'Sign in to send messages.';
  }

  if (error is PostgrestException) {
    return switch (error.code) {
      '42501' => 'You do not have permission to do that.',
      '22023' => 'You cannot start a conversation with yourself.',
      'P0002' => 'That item is no longer available.',
      '23503' => 'The listing for this conversation is no longer available.',
      _ => _clean(error.message),
    };
  }

  if (error is SocketException) {
    return 'Network error. Check your connection and try again.';
  }

  if (error is StateError) return _clean(error.message);
  if (error is FormatException) return 'That message could not be sent.';

  return _clean(
    error.toString(),
    fallback: 'Something went wrong. Please try again.',
  );
}

String _clean(
  String raw, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final message = raw.trim();
  if (message.isEmpty || message.toLowerCase() == 'exception') return fallback;
  return message;
}
