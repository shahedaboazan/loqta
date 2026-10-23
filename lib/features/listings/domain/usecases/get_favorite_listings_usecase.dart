import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';

/// Loads the signed-in user's favourite listings for the Favorites screen.
class GetFavoriteListingsUseCase {
  const GetFavoriteListingsUseCase(this._repository);

  final FavoritesRepository _repository;

  Future<List<Listing>> call() => _repository.fetchFavoriteListings();
}
