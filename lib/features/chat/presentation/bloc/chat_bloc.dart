import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/entities/message.dart';
import 'package:loqta/features/chat/domain/errors/chat_failure.dart';
import 'package:loqta/features/chat/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:loqta/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:loqta/features/chat/domain/usecases/watch_messages_usecase.dart';

/// Drives one open conversation (Screen 14).
///
/// Owns the message list, the realtime subscription and the read cursor. The
/// subscription is opened on [ChatStarted] and cancelled when the bloc closes,
/// so leaving the screen always tears the channel down.
sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInProgress extends ChatState {
  const ChatInProgress();
}

/// [messages] is ordered oldest-first and free of duplicates.
class ChatSuccess extends ChatState {
  const ChatSuccess({
    required this.conversation,
    required this.messages,
    this.isSending = false,
    this.isUploading = false,
    this.transientError,
  });

  final Conversation? conversation;
  final List<Message> messages;
  final bool isSending;
  final bool isUploading;

  /// A non-fatal failure (a send that did not go through). The loaded history
  /// stays on screen.
  final String? transientError;

  ChatSuccess copyWith({
    Conversation? conversation,
    List<Message>? messages,
    bool? isSending,
    bool? isUploading,
    String? transientError,
    bool clearTransientError = false,
  }) => ChatSuccess(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    isSending: isSending ?? this.isSending,
    isUploading: isUploading ?? this.isUploading,
    transientError: clearTransientError
        ? null
        : (transientError ?? this.transientError),
  );

  @override
  List<Object?> get props => [
    conversation,
    messages,
    isSending,
    isUploading,
    transientError,
  ];
}

/// The conversation could not be opened.
///
/// Deliberately not named `ChatFailure`: that name belongs to the domain error
/// the repository throws, and shadowing it here meant every `on ChatFailure
/// catch` in this file was catching this state instead, discarding the mapped
/// copy the repository had already produced.
class ChatLoadFailure extends ChatState {
  const ChatLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the history and opens the realtime subscription.
class ChatStarted extends ChatEvent {
  const ChatStarted(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Re-reads the history, e.g. after returning from the Image Viewer.
class ChatHistoryReloaded extends ChatEvent {
  const ChatHistoryReloaded();
}

class ChatMessageSent extends ChatEvent {
  const ChatMessageSent(this.content);

  final String content;

  @override
  List<Object?> get props => [content];
}

/// Sends an image attachment. The bytes are already in memory; uploading and
/// recording the message is the bloc's job.
///
/// [bytes] is a `Uint8List` because that is what the storage client accepts, and
/// that is also what a file read produces on the platform.
class ChatImageAttached extends ChatEvent {
  const ChatImageAttached({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  @override
  List<Object?> get props => [fileName, bytes.length];
}

/// Internal event raised by the realtime subscription.
class ChatRealtimeMessage extends ChatEvent {
  const ChatRealtimeMessage(this.message);

  final Message message;

  @override
  List<Object?> get props => [message];
}

/// Internal event raised when the subscription reports a failure.
class ChatRealtimeFailed extends ChatEvent {
  const ChatRealtimeFailed();
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this._watchMessages,
    required this._sendMessage,
    required this._sendImageMessage,
    required this._markRead,
    required this._getConversation,
    required this._conversation,
  }) : super(const ChatInProgress()) {
    on<ChatStarted>(_onStarted);
    on<ChatHistoryReloaded>(_onReloaded);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatImageAttached>(_onImageAttached);
    on<ChatRealtimeMessage>(_onRealtimeMessage);
    on<ChatRealtimeFailed>(_onRealtimeFailed);
  }

  final WatchMessagesUseCase _watchMessages;
  final SendMessageUseCase _sendMessage;
  final SendImageMessageUseCase _sendImageMessage;
  final MarkConversationReadUseCase _markRead;
  final GetConversationUseCase _getConversation;

  final Conversation? _conversation;

  String _conversationId = '';

  /// Ids already in the list.
  ///
  /// This is what stops a message appearing twice: the sender's own insert
  /// arrives both as the value returned by the insert call and as a realtime
  /// INSERT event for the same row.
  final Set<String> _seenMessageIds = <String>{};

  StreamSubscription<Message>? _subscription;

  @override
  Future<void> close() async {
    // Leaving the screen removes the Realtime channel rather than leaking it.
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    _conversationId = event.conversationId;
    emit(const ChatInProgress());

    try {
      final history = await _watchMessages.history(_conversationId);
      _seenMessageIds
        ..clear()
        ..addAll(history.map((message) => message.id));

      emit(
        ChatSuccess(conversation: _conversation, messages: _sorted(history)),
      );

      // The header's participant and listing context are resolved from the
      // server, so they are correct however this screen was opened. A failure
      // here only means the caller's own values stay in place.
      final conversation = await _resolveConversation();
      final loaded = state;
      if (conversation != null && loaded is ChatSuccess) {
        emit(loaded.copyWith(conversation: conversation));
      }
    } on ChatFailure catch (failure) {
      emit(ChatLoadFailure(failure.message));
      return;
    } catch (_) {
      emit(const ChatLoadFailure('This conversation could not be opened.'));
      return;
    }

    // Opening the conversation clears the unread badge. This runs outside the
    // load above on purpose: a read-cursor failure must not discard a history
    // that loaded perfectly well, and it must not stop the subscription.
    await _markReadSafely(emit);

    await _subscription?.cancel();
    _subscription = _watchMessages
        .realtime(_conversationId)
        .listen(
          (message) => add(ChatRealtimeMessage(message)),
          onError: (_) => add(const ChatRealtimeFailed()),
        );
  }

  /// Reads the conversation's own record, returning null when it cannot be read.
  ///
  /// Only the header uses this, so a failure degrades to the values the opening
  /// screen already supplied instead of failing the whole screen.
  Future<Conversation?> _resolveConversation() async {
    try {
      return await _getConversation(_conversationId);
    } on ChatFailure {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Advances the read cursor without ever letting its failure take down the
  /// conversation.
  ///
  /// The failure is reported through the same transient channel as a send, so it
  /// is visible rather than swallowed.
  Future<void> _markReadSafely(Emitter<ChatState> emit) async {
    try {
      await _markRead(_conversationId);
    } on ChatFailure catch (failure) {
      final current = state;
      if (current is ChatSuccess) {
        emit(current.copyWith(transientError: failure.message));
      }
    } catch (_) {
      final current = state;
      if (current is ChatSuccess) {
        emit(
          current.copyWith(
            transientError: 'Your read receipt could not be sent.',
          ),
        );
      }
    }
  }

  Future<void> _onReloaded(
    ChatHistoryReloaded event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId.isEmpty) return;
    try {
      final history = await _watchMessages.history(_conversationId);
      _seenMessageIds
        ..clear()
        ..addAll(history.map((message) => message.id));
      final current = state;
      emit(
        ChatSuccess(
          conversation: current is ChatSuccess
              ? current.conversation
              : _conversation,
          messages: _sorted(history),
          isSending: current is ChatSuccess ? current.isSending : false,
          isUploading: current is ChatSuccess ? current.isUploading : false,
        ),
      );
    } on ChatFailure {
      // Keep whatever is already on screen.
    } catch (_) {
      // Keep whatever is already on screen.
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatSuccess) return;

    final content = event.content.trim();
    if (content.isEmpty) return;
    // Ignore a second tap while the first send is still in flight.
    if (current.isSending) return;

    emit(current.copyWith(isSending: true, clearTransientError: true));

    try {
      final sent = await _sendMessage(
        conversationId: _conversationId,
        content: content,
      );
      _seenMessageIds.add(sent.id);
      emit(
        current.copyWith(
          messages: _sorted([...current.messages, sent]),
          isSending: false,
        ),
      );
    } on ChatFailure catch (failure) {
      emit(current.copyWith(isSending: false, transientError: failure.message));
    } catch (_) {
      emit(
        current.copyWith(
          isSending: false,
          transientError: 'That message could not be sent.',
        ),
      );
    }
  }

  Future<void> _onImageAttached(
    ChatImageAttached event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatSuccess) return;
    if (current.isUploading) return;

    emit(current.copyWith(isUploading: true, clearTransientError: true));

    try {
      final sent = await _sendImageMessage(
        conversationId: _conversationId,
        bytes: event.bytes,
        fileName: event.fileName,
      );

      if (sent == null) {
        emit(current.copyWith(isUploading: false));
        return;
      }

      _seenMessageIds.add(sent.id);
      emit(
        current.copyWith(
          messages: _sorted([...current.messages, sent]),
          isUploading: false,
        ),
      );
    } on ChatFailure catch (failure) {
      emit(
        current.copyWith(isUploading: false, transientError: failure.message),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isUploading: false,
          transientError: 'That photo could not be sent.',
        ),
      );
    }
  }

  /// Merges a realtime insert into the list.
  Future<void> _onRealtimeMessage(
    ChatRealtimeMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatSuccess) return;

    // The same row arrives as the response to our own insert and again as a
    // realtime event. Ignoring ids already present is what keeps one bubble.
    if (!_seenMessageIds.add(event.message.id)) return;

    emit(
      current.copyWith(messages: _sorted([...current.messages, event.message])),
    );

    // Reading the conversation keeps the sender's unread count accurate. The
    // failure is surfaced rather than swallowed: a stale badge is something the
    // user needs to know about.
    await _markReadSafely(emit);
  }

  void _onRealtimeFailed(ChatRealtimeFailed event, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatSuccess) return;
    emit(
      current.copyWith(transientError: 'Live updates paused. Pull to refresh.'),
    );
  }

  /// Oldest first, with the unique id as a tie-breaker so two messages written
  /// in the same millisecond keep a fixed order.
  static List<Message> _sorted(List<Message> messages) {
    final copy = [...messages];
    copy.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return copy;
  }
}
