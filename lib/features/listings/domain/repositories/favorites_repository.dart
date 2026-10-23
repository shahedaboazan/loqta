import 'package:loqta/features/listings/domain/entities/listing.dart';

/// The authenticated user's favourite listings.
///
/// Favourites are private: the repository only ever reads or writes rows for
/// the signed-in user id, and Row Level Security on `public.favorites` rejects
/// any attempt to touch somebody else's.
abstract class FavoritesRepository {
  Future<List<Listing>> fetchFavoriteListings();

  /// Adds or removes the favourite and returns the state the row ended up in.
  Future<bool> toggle(String listingId);
}
