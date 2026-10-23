import 'dart:async';
import 'dart:typed_data';

import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/entities/message.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';
import 'package:loqta/features/chat/domain/services/image_picker_service.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/notifications/domain/entities/app_notification.dart';
import 'package:loqta/features/notifications/domain/errors/notification_failure.dart';
import 'package:loqta/features/notifications/domain/repositories/notification_repository.dart';
import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';
import 'package:loqta/features/profile/domain/entities/user_profile.dart';
import 'package:loqta/features/profile/domain/repositories/profile_repository.dart';

/// In-memory [FavoritesRepository] for widget tests.
///
/// Mirrors the real registration in `lib/main.dart`. [rows] is what
/// `fetchFavoriteListings` returns, so a test can drive both the populated and
/// the empty state of the Favorites screen.
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({this.rows = const []});

  final List<Listing> rows;

  /// Listing ids passed to [toggle], in call order, so a test can assert the
  /// screen actually wrote through the repository.
  final List<String> toggled = [];

  /// When set, the next [toggle] throws it instead of succeeding.
  Object? toggleError;

  @override
  Future<List<Listing>> fetchFavoriteListings() async => rows;

  @override
  Future<bool> toggle(String listingId) async {
    toggled.add(listingId);
    final error = toggleError;
    if (error != null) throw error;
    // A toggle from the Favorites screen removes the row.
    return false;
  }
}

/// In-memory [ChatRepository] for widget tests.
///
/// Holds a message history, a realtime stream a test can push into, and a record
/// of what the screens asked the server for.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    Conversation? conversation,
    this.conversations,
    List<Message>? history,
    this.historyError,
    this.sendError,
    this.markReadError,
    this.uploadError,
  }) : conversation = conversation ?? conversationFixture(),
       _history = history ?? <Message>[];

  final Conversation conversation;

  /// What the Chat List reads. Defaults to the single [conversation].
  final List<Conversation>? conversations;

  final List<Message> _history;

  /// When set, `fetchMessages` throws it, which is how the Chat screen's error
  /// and retry states are exercised.
  final Object? historyError;

  /// When set, `sendMessage` throws it.
  final Object? sendError;

  /// When set, `markRead` throws it, which is how a failing read cursor is
  /// exercised.
  final Object? markReadError;

  /// When set, `sendImageMessage` throws it, which is how a failed upload is
  /// exercised.
  final Object? uploadError;

  /// Realtime inserts the Chat screen subscribes to.
  final StreamController<Message> _incoming =
      StreamController<Message>.broadcast();

  /// Conversation-activity events the Chat List subscribes to.
  final StreamController<void> _activity = StreamController<void>.broadcast();

  /// Conversation ids passed to [markRead], so a test can prove the read cursor
  /// was advanced for this thread.
  final List<String> markedRead = [];

  /// Listing ids passed to [getOrCreateConversation].
  final List<String> requestedListingIds = [];

  /// Conversation ids passed to [fetchConversation], so a test can prove the
  /// header's context is resolved from the repository.
  final List<String> requestedConversationIds = [];

  /// Delivers [message] as a realtime insert.
  void emitRealtime(Message message) => _incoming.add(message);

  /// Fires conversation activity, as a new message elsewhere would.
  void emitActivity() => _activity.add(null);

  Future<void> dispose() async {
    await _incoming.close();
    await _activity.close();
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String listingId,
    required String listingTitle,
    String? listingImageUrl,
    double? listingPrice,
    bool isDonation = false,
  }) async {
    requestedListingIds.add(listingId);
    return conversation;
  }

  @override
  Future<List<Conversation>> fetchConversations() async =>
      conversations ?? [conversation];

  @override
  Future<Conversation> fetchConversation(String conversationId) async {
    requestedConversationIds.add(conversationId);
    return conversation;
  }

  @override
  Future<List<Message>> fetchMessages(String conversationId) async {
    final error = historyError;
    if (error != null) throw error;
    return List<Message>.of(_history);
  }

  @override
  Stream<Message> watchMessages(String conversationId) => _incoming.stream;

  @override
  Stream<void> watchConversationActivity() => _activity.stream;

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final error = sendError;
    if (error != null) throw error;

    final sent = Message(
      id: 'sent-${_history.length + 1}',
      conversationId: conversationId,
      senderId: 'buyer-1',
      content: content,
      createdAt: DateTime(2026, 1, 1, 10, _history.length),
      isMine: true,
    );
    _history.add(sent);
    return sent;
  }

  /// Byte length, conversation id and file name of every image upload, so a
  /// test can prove the picked bytes really reached the storage layer.
  final List<(int, String, String)> uploads = [];

  @override
  Future<Message?> sendImageMessage({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
    String content = '',
  }) async {
    uploads.add((bytes.length, conversationId, fileName));
    final error = uploadError;
    if (error != null) throw error;

    final sent = Message(
      id: 'image-${uploads.length}',
      conversationId: conversationId,
      senderId: 'buyer-1',
      content: content,
      createdAt: DateTime(2026, 1, 1, 11, uploads.length),
      isMine: true,
      attachmentPath: 'conversations/$conversationId/$fileName',
      attachmentMime: 'image/jpeg',
      attachmentUrl: 'https://example.invalid/$fileName',
    );
    _history.add(sent);
    return sent;
  }

  @override
  Future<void> markRead(String conversationId) async {
    markedRead.add(conversationId);
    final error = markReadError;
    if (error != null) throw error;
  }

  @override
  Future<String> signedAttachmentUrl(String path) async =>
      'https://example.invalid/$path';
}

/// A conversation with a listing attached, as `my_conversations()` returns it.
Conversation conversationFixture({int unreadCount = 0, String? preview}) {
  return Conversation(
    id: 'conversation-1',
    listingId: 'l1',
    buyerId: 'buyer-1',
    sellerId: 'seller-l1',
    lastMessageAt: DateTime(2026, 1, 1, 9, 30),
    unreadCount: unreadCount,
    otherParticipantId: 'seller-l1',
    otherParticipantName: 'Omar Al-Hassan',
    latestMessagePreview: preview,
    listing: Listing(
      id: 'l1',
      sellerId: 'seller-l1',
      title: 'Modern Fabric Sofa',
      description: '',
      category: 'Furniture',
      condition: 'Good Condition',
      type: ListingType.sale,
      price: 1500000,
      imageUrls: const [],
      governorate: 'Damascus',
      area: 'Mazzeh',
      status: ListingStatus.active,
      createdAt: DateTime(2026, 1, 1),
    ),
  );
}

/// One message in a conversation.
Message messageFixture({
  required String id,
  required String content,
  bool isMine = false,
  bool attachment = false,
  String? attachmentUrl,
}) {
  return Message(
    id: id,
    conversationId: 'conversation-1',
    senderId: isMine ? 'buyer-1' : 'seller-l1',
    content: content,
    createdAt: DateTime(2026, 1, 1, 10),
    isMine: isMine,
    attachmentPath: attachment ? 'conversations/conversation-1/$id.jpg' : null,
    attachmentMime: attachment ? 'image/jpeg' : null,
    attachmentUrl: attachmentUrl,
  );
}

/// In-memory [ImagePickerService], so the Chat screen's attachment path can be
/// driven from a test without a device.
class FakeImagePickerService implements ImagePickerService {
  FakeImagePickerService({this.result, this.error});

  /// What the next pick returns. Null means the user cancelled.
  PickedImage? result;

  /// When set, the next pick throws it instead of returning.
  Object? error;

  /// How many times the picker was invoked, so a test can prove repeated taps
  /// did not open it more than once.
  int calls = 0;

  @override
  Future<PickedImage?> pickImage() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

/// In-memory [NotificationRepository] for widget tests.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({this.rows = const [], this.fetchError});

  final List<AppNotification> rows;

  /// When set, `fetchNotifications` throws it.
  final Object? fetchError;

  /// Ids passed to `markRead`, in call order.
  final List<String> markedRead = [];

  /// How many times `markAllRead` was called.
  int markAllReadCalls = 0;

  final StreamController<AppNotification> _incoming =
      StreamController<AppNotification>.broadcast();

  /// Delivers a realtime insert.
  void emit(AppNotification notification) => _incoming.add(notification);

  /// Reports a broken realtime subscription.
  void failStream() =>
      _incoming.addError(const NotificationFailure('stream down'));

  Future<void> dispose() => _incoming.close();

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final error = fetchError;
    if (error != null) throw error;
    return List<AppNotification>.of(rows);
  }

  @override
  Stream<AppNotification> watchNotifications() => _incoming.stream;

  @override
  Future<void> markRead(String notificationId) async {
    markedRead.add(notificationId);
  }

  @override
  Future<void> markAllRead() async {
    markAllReadCalls++;
  }
}

/// In-memory [ProfileRepository] for widget tests.
///
/// Mirrors the real registration in `lib/main.dart`, so screens hosted above
/// the shell can load and update a profile without Supabase.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.profile});

  UserProfile? profile;

  @override
  Future<UserProfile?> fetchCurrentProfile() async => profile;

  @override
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? governorate,
    String? area,
    String? phoneNumber,
  }) async {
    final saved = UserProfile(
      id: profile?.id ?? 'u1',
      firstName: firstName ?? profile?.firstName,
      lastName: lastName ?? profile?.lastName,
      avatarUrl: avatarUrl ?? profile?.avatarUrl,
      governorate: governorate ?? profile?.governorate,
      area: area ?? profile?.area,
      phoneNumber: phoneNumber ?? profile?.phoneNumber,
    );
    profile = saved;
    return saved;
  }
}

/// One in-app notification row.
AppNotification notificationFixture({
  required String id,
  String title = 'New message',
  String body = 'You have a new message.',
  bool isRead = false,
  String? listingId,
  String? conversationId,
  NotificationType type = NotificationType.newMessage,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    userId: 'u1',
    type: type,
    title: title,
    body: body,
    createdAt: createdAt ?? DateTime.now(),
    listingId: listingId,
    conversationId: conversationId,
    readAt: isRead ? DateTime.now() : null,
  );
}
