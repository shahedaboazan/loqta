import 'dart:typed_data';

import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/entities/message.dart';

/// Reads and writes chat data.
///
/// Every method is scoped by the caller id on the server: the repository never
/// sends a sender id or a participant list, because Row Level Security derives
/// both from the session token.
abstract class ChatRepository {
  /// Returns the conversation for ([listingId]) and the signed-in user,
  /// creating it only when it does not already exist.
  ///
  /// Idempotent by design: the database's unique constraint on
  /// (listing_id, buyer_id, seller_id) plus an upsert in
  /// `get_or_create_conversation` means repeated taps cannot produce duplicate
  /// threads.
  Future<Conversation> getOrCreateConversation({
    required String listingId,
    required String listingTitle,
    String? listingImageUrl,
    double? listingPrice,
    bool isDonation = false,
  });

  /// All conversations the signed-in user participates in, newest activity
  /// first.
  ///
  /// Optionally filtered by [listingId].
  Future<List<Conversation>> fetchConversations({String? listingId});

  /// One conversation by id, resolved for the signed-in user.
  ///
  /// Throws when the conversation does not exist or the caller is not a
  /// participant: the server's `my_conversations` RPC is the only source, so it
  /// cannot return somebody else's thread.
  Future<Conversation> fetchConversation(String conversationId);

  /// Existing message history, oldest first.
  Future<List<Message>> fetchMessages(String conversationId);

  /// Realtime INSERTs for one conversation.
  ///
  /// The stream is a broadcast stream so several listeners can attach; the
  /// repository removes the underlying Supabase channel when the last listener
  /// cancels.
  Stream<Message> watchMessages(String conversationId);

  /// Fires whenever a conversation's activity changes, so the Chat List can
  /// refresh its ordering and unread badges without polling.
  Stream<void> watchConversationActivity();

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  });

  /// Uploads [bytes] to Supabase Storage and records the attachment on a new
  /// message. Returns null when there is no message content to attach to.
  Future<Message?> sendImageMessage({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
    String content = '',
  });

  /// Advances the signed-in user's read cursor for [conversationId].
  Future<void> markRead(String conversationId);

  /// A short-lived signed URL so an attachment can be rendered or opened in the
  /// Image Viewer without making the bucket public.
  Future<String> signedAttachmentUrl(String path);
}
