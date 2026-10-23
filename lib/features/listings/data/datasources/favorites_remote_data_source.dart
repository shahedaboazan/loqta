import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/listings/data/models/listing_model.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';

/// Reads and writes the signed-in user's rows in `public.favorites`.
///
/// Every statement is scoped by RLS to `auth.uid()`, so the user id never has
/// to be sent from the device — the database derives it. That is what stops a
/// tampered client from reading or writing somebody else's favourites.
class FavoritesRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<List<Listing>> fetchFavoriteListings() async {
    final userId = _currentUserId;
    if (userId == null) return const [];

    // `saved_at` is the favourite row's own created_at, aliased so it cannot be
    // confused with the listing's created_at. The listing is embedded so its
    // data comes back in the same round trip; RLS on `listings` still applies.
    final rows = await _client
        .from('favorites')
        .select(
          'saved_at:created_at, listing:listings(${ListingModel.selectColumns})',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .order('listing_id', ascending: false);

    return rows
        .whereType<Map>()
        .map((row) {
          final listing = row['listing'];
          // A listing the user can no longer read comes back null and is
          // skipped rather than rendered as an empty row.
          if (listing is! Map) return null;

          final savedAt = DateTime.tryParse(row['saved_at'] as String? ?? '');
          return ListingModel.fromRow(
            Map<String, dynamic>.from(listing),
            currentUserId: userId,
            savedAt: savedAt?.toLocal(),
          );
        })
        .whereType<Listing>()
        .toList();
  }

  /// Returns true when the listing is now a favourite, false when removed.
  Future<bool> toggle(String listingId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw const FavoritesUnavailableException();
    }

    // The delete reports the rows it actually removed, so the returned state is
    // the database's own answer rather than a guess made before the write.
    final removed = await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('listing_id', listingId)
        .select('listing_id');

    if (removed.isNotEmpty) return false;

    // A concurrent insert can still lose the (user_id, listing_id) unique
    // constraint; that error propagates instead of being reported as success.
    await _client.from('favorites').insert({
      'user_id': userId,
      'listing_id': listingId,
    });
    return true;
  }
}

/// Raised when there is no session, so there is nobody to own a favourite.
class FavoritesUnavailableException implements Exception {
  const FavoritesUnavailableException();

  @override
  String toString() => 'FavoritesUnavailableException';
}
