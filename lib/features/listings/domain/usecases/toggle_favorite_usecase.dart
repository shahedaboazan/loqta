import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';

/// Adds or removes a favourite on behalf of the signed-in user.
///
/// Returns the resulting state so the heart on Listing Details can flip
/// without a refetch.
class ToggleFavoriteUseCase {
  const ToggleFavoriteUseCase(this._repository);

  final FavoritesRepository _repository;

  Future<bool> call(String listingId) => _repository.toggle(listingId);
}
