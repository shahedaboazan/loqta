import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';

/// Advances the signed-in user's read cursor when a conversation is opened or
/// new messages arrive.
///
/// Scoped on the server to `auth.uid()`, so a client cannot clear somebody
/// else's unread badge.
class MarkConversationReadUseCase {
  const MarkConversationReadUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String conversationId) =>
      _repository.markRead(conversationId);
}
