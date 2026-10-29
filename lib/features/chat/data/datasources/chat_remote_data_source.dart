import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/chat/data/models/conversation_model.dart';
import 'package:loqta/features/chat/data/models/message_model.dart';
import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/entities/message.dart';

/// Raised when the caller is not signed in, so there is no session to scope the
/// query to.
class ChatUnavailableException implements Exception {
  const ChatUnavailableException();

  @override
  String toString() => 'ChatUnavailableException';
}

/// Supabase access for chat: RPCs for conversation creation, PostgREST for
/// history and sends, Realtime for live inserts, and Storage for attachments.
class ChatRemoteDataSource {
  /// Private bucket holding chat attachments. See the Storage policies in
  /// `supabase/migrations`.
  static const String attachmentsBucket = 'chat-attachments';

  /// Realtime channel prefix; one channel per open conversation.
  static const String channelPrefix = 'chat:conversation:';

  /// Realtime channel used by the Chat List to notice activity changes.
  static const String activityChannel = 'chat:activity';

  SupabaseClient get _client => Supabase.instance.client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const ChatUnavailableException();
    return id;
  }

  // ---------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------

  /// Calls the `get_or_create_conversation` RPC.
  ///
  /// The RPC resolves the seller from the listing itself and upserts on the
  /// unique (listing_id, buyer_id, seller_id) constraint, so two rapid taps
  /// produce one conversation rather than two. The Flutter layer never sends a
  /// participant id.
  Future<String> resolveConversationId(String listingId) async {
    _currentUserId;
    final data = await _client.rpc(
      'get_or_create_conversation',
      params: {'p_listing_id': listingId},
    );

    final id = data is String
        ? data
        : (data is List && data.isNotEmpty)
        ? data.first.toString()
        : null;

    if (id == null || id.isEmpty) {
      throw const ChatUnavailableException();
    }
    return id;
  }

  Future<List<Conversation>> fetchConversations({String? listingId}) async {
    _currentUserId;
    // If listingId is provided, the RPC needs to filter by it
    // Check if my_conversations RPC supports arguments
    final rows = await _client.rpc(
      'my_conversations',
      params: listingId != null ? {'p_listing_id': listingId} : {},
    );
    return ConversationModel.fromRows(rows ?? const []);
  }

  /// Reads the single conversation the Chat screen needs for its header.
  Future<Conversation> fetchConversation(String conversationId) async {
    final conversations = await fetchConversations();
    return conversations.firstWhere(
      (conversation) => conversation.id == conversationId,
      orElse: () => throw const ChatUnavailableException(),
    );
  }

  // ---------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------

  Future<List<Message>> fetchMessages(String conversationId) async {
    final userId = _currentUserId;
    final rows = await _client
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .order('id', ascending: true);

    final messages = MessageModel.fromRows(rows, currentUserId: userId);

    // Attachments are private, so each row needs its own short-lived URL.
    return _withSignedUrls(messages);
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final userId = _currentUserId;
    final row = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': content,
        })
        .select('*')
        .single();

    return MessageModel.fromRow(row, currentUserId: userId);
  }

  /// Uploads [bytes] into `conversations/<conversationId>/…`, then records the
  /// object path on a new message.
  ///
  /// Only the path is stored. The database never holds image data, and the
  /// returned message carries a signed URL so the bubble can render immediately.
  Future<Message?> sendImageMessage({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
    String content = '',
  }) async {
    if (bytes.isEmpty) return null;

    final userId = _currentUserId;
    // The first path segment must be the conversation id: the storage policies
    // read `storage.foldername(name)[1]` and cast it to uuid to check
    // participation.
    final objectPath =
        'conversations/$conversationId/${DateTime.now().microsecondsSinceEpoch}_$fileName';

    // `uploadBinary` resolves with the stored object key and throws a
    // StorageException on failure, so a successful return is the only success
    // signal. The message is carried through unchanged: ChatRepositoryImpl maps
    // it into a ChatFailure the Chat screen shows.
    String uploadedPath;
    try {
      uploadedPath = await _client.storage
          .from(attachmentsBucket)
          .uploadBinary(objectPath, bytes);
    } on StorageException catch (error) {
      throw StateError(error.message);
    }

    if (uploadedPath.isEmpty) {
      throw StateError('The attachment could not be uploaded.');
    }

    final row = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': content,
          'attachment_path': objectPath,
          'attachment_mime': _mimeFor(fileName),
        })
        .select('*')
        .single();

    final message = MessageModel.fromRow(row, currentUserId: userId);

    return message.copyWith(
      attachmentPath: objectPath,
      attachmentUrl: await signedAttachmentUrl(objectPath),
    );
  }

  /// Resolves a short-lived signed URL for a private attachment. The
  /// `conversations/<conversation id>/…` key layout is what the storage
  /// policies check with `storage.foldername(name)[1]`.

  Future<String> signedAttachmentUrl(String path) async {
    // createSignedUrl resolves with the URL itself and throws a
    // StorageException when the object is missing or unreadable.
    final String url;
    try {
      url = await _client.storage
          .from(attachmentsBucket)
          .createSignedUrl(path, const Duration(minutes: 30).inSeconds);
    } on StorageException catch (error) {
      throw StateError(error.message);
    }

    if (url.isEmpty) {
      throw StateError('The image could not be opened.');
    }
    return url;
  }

  Future<List<Message>> _withSignedUrls(List<Message> messages) async {
    final resolved = <Message>[];

    for (final message in messages) {
      final path = message.attachmentPath;
      if (path == null) {
        resolved.add(message);
        continue;
      }

      try {
        resolved.add(
          message.copyWith(attachmentUrl: await signedAttachmentUrl(path)),
        );
      } catch (_) {
        // One unreadable attachment must not blank the whole conversation; the
        // bubble falls back to its error state.
        resolved.add(message);
      }
    }

    return resolved;
  }

  static String _mimeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  // ---------------------------------------------------------------------
  // Realtime
  // ---------------------------------------------------------------------

  /// Realtime INSERTs for one conversation.
  ///
  /// A channel is created per subscription and removed when the last listener
  /// cancels, so leaving the Chat screen tears the listener down instead of
  /// leaking a subscription.
  Stream<Message> watchMessages(String conversationId) {
    final controller = StreamController<Message>();
    RealtimeChannel? channel;
    var closed = false;

    Future<void> start() async {
      final userId = _currentUserId;
      channel = _client.channel('$channelPrefix$conversationId');
      channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            // Only this conversation's rows, so two open chats cannot cross-feed.
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) async {
              if (closed) return;
              final raw = payload.newRecord;
              if (raw.isEmpty) return;

              final message = MessageModel.fromRow(
                Map<String, dynamic>.from(raw),
                currentUserId: userId,
              );

              if (message.attachmentPath != null &&
                  message.attachmentUrl == null) {
                try {
                  controller.add(
                    message.copyWith(
                      attachmentUrl: await signedAttachmentUrl(
                        message.attachmentPath!,
                      ),
                    ),
                  );
                  return;
                } catch (_) {
                  // Fall through and emit the bubble without a URL so the UI can
                  // show its own retry affordance.
                }
              }

              controller.add(message);
            },
          )
          .subscribe();
    }

    // onListen/onCancel give the channel the same lifecycle as the stream.
    controller.onListen = () {
      start();
    };

    controller.onCancel = () {
      closed = true;
      final current = channel;
      channel = null;
      if (current != null) {
        // Fire and forget: the channel is discarded either way.
        unawaited(_client.removeChannel(current));
      }
    };

    return controller.stream;
  }

  /// Emits whenever a conversation row changes, so the Chat List can refresh
  /// its ordering and unread badges.
  Stream<void> watchConversationActivity() {
    final controller = StreamController<void>();
    RealtimeChannel? channel;
    var closed = false;

    controller.onListen = () {
      final current = _client.channel(activityChannel);
      channel = current;
      current
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            callback: (payload) {
              if (closed) return;
              // RLS does not apply to Realtime payloads, so re-check locally:
              // only react to rows the signed-in user is part of.
              final row = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;
              final userId = _client.auth.currentUser?.id;
              if (userId != null) {
                final participates =
                    row['buyer_id'] == userId || row['seller_id'] == userId;
                if (!participates) return;
              }
              controller.add(null);
            },
          )
          .subscribe();
    };

    controller.onCancel = () {
      closed = true;
      final current = channel;
      channel = null;
      if (current != null) {
        unawaited(_client.removeChannel(current));
      }
    };

    return controller.stream;
  }

  // ---------------------------------------------------------------------
  // Read status
  // ---------------------------------------------------------------------

  /// Advances the caller's own read cursor.
  ///
  /// Delegated to the `mark_conversation_read` RPC, which checks
  /// participation on the server and writes only the caller's row — so a
  /// tampered client cannot clear another user's unread badge.
  Future<void> markRead(String conversationId) async {
    _currentUserId;
    await _client.rpc(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }
}
