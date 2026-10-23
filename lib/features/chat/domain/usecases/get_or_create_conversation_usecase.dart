import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';

/// Resolves (or creates) the conversation for a listing and the signed-in user,
/// then hands back the object the Chat screen needs.
///
/// This is what "Contact Seller" calls. It is idempotent, so tapping the button
/// repeatedly keeps returning the same conversation instead of spawning new
/// threads.
class GetOrCreateConversationUseCase {
  const GetOrCreateConversationUseCase(this._repository);

  final ChatRepository _repository;

  Future<Conversation> call({
    required String listingId,
    required String listingTitle,
    String? listingImageUrl,
    double? listingPrice,
    bool isDonation = false,
  }) => _repository.getOrCreateConversation(
    listingId: listingId,
    listingTitle: listingTitle,
    listingImageUrl: listingImageUrl,
    listingPrice: listingPrice,
    isDonation: isDonation,
  );
}
