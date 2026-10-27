import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/errors/chat_failure.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';
import 'package:loqta/features/chat/domain/usecases/get_conversations_usecase.dart';

/// Drives the Chat List (Screen 16).
///
/// Loads conversations ordered by latest activity and re-reads them when Realtime
/// reports conversation activity, so ordering and unread badges stay live.
sealed class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

class ConversationsInProgress extends ConversationsState {
  const ConversationsInProgress();
}

class ConversationsSuccess extends ConversationsState {
  const ConversationsSuccess(this.conversations);

  final List<Conversation> conversations;

  @override
  List<Object?> get props => [conversations];
}

class ConversationsFailure extends ConversationsState {
  const ConversationsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => [];
}

class ConversationsRequested extends ConversationsEvent {
  const ConversationsRequested({this.listingId});

  final String? listingId;

  @override
  List<Object?> get props => [listingId];
}

/// Internal event raised by the Realtime activity subscription.
class ConversationsActivityDetected extends ConversationsEvent {
  const ConversationsActivityDetected();
}

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc({
    required GetConversationsUseCase getConversations,
    required ChatRepository chatRepository,
  }) : _getConversations = getConversations,
       _chatRepository = chatRepository,
       super(const ConversationsInProgress()) {
    on<ConversationsRequested>(_onRequested);
    on<ConversationsActivityDetected>(_onActivityDetected);
  }

  final GetConversationsUseCase _getConversations;
  final ChatRepository _chatRepository;

  StreamSubscription<void>? _subscription;

  /// True while a read is in flight, so a burst of activity events cannot pile
  /// up duplicate requests.
  bool _isRefreshing = false;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }

  Future<void> _onRequested(
    ConversationsRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(const ConversationsInProgress());

    try {
      final conversations = await _getConversations(listingId: event.listingId);
      emit(ConversationsSuccess(conversations));

      await _subscription?.cancel();
      _subscription = _chatRepository.watchConversationActivity().listen(
        (_) => add(const ConversationsActivityDetected()),
      );
    } on ChatFailure catch (failure) {
      emit(ConversationsFailure(failure.message));
    } catch (_) {
      emit(const ConversationsFailure('Your messages could not be loaded.'));
    }
  }

  Future<void> _onActivityDetected(
    ConversationsActivityDetected event,
    Emitter<ConversationsState> emit,
  ) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final conversations = await _getConversations();
      // Keep the list on screen while refreshing; only errors replace it.
      emit(ConversationsSuccess(conversations));
    } on ChatFailure catch (failure) {
      final current = state;
      if (current is! ConversationsSuccess) {
        emit(ConversationsFailure(failure.message));
      }
    } catch (_) {
      // Leave the existing list alone.
    } finally {
      _isRefreshing = false;
    }
  }
}
