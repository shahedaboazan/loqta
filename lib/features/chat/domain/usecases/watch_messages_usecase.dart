import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/entities/message.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';

/// Reads the conversation the Chat screen renders its header from.
///
/// The header's participant name and listing context come from the server's own
/// view of the thread rather than from whatever the calling screen passed in.
class GetConversationUseCase {
  const GetConversationUseCase(this._repository);

  final ChatRepository _repository;

  Future<Conversation> call(String conversationId) =>
      _repository.fetchConversation(conversationId);
}

class WatchMessagesUseCase {
  const WatchMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<Message>> history(String conversationId) =>
      _repository.fetchMessages(conversationId);

  Stream<Message> realtime(String conversationId) =>
      _repository.watchMessages(conversationId);
}
