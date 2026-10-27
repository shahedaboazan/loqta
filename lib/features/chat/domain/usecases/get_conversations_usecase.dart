import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';

/// Loads the Chat List, ordered by the latest message activity.
class GetConversationsUseCase {
  const GetConversationsUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<Conversation>> call({String? listingId}) =>
      _repository.fetchConversations(listingId: listingId);
}
