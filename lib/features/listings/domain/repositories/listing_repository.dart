import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/entities/listing_draft.dart';
import 'package:loqta/features/listings/domain/entities/listing_page.dart';

/// Reads listing data.
///
/// Deliberately has no filter parameters: the approved Search design has a
/// single keyword input and no filter affordances.
abstract class ListingRepository {
  /// The "Featured Finds" rows on Home.
  Future<List<Listing>> fetchFeatured({int limit = 6});

  /// One page of listings with optional filters.
  Future<ListingPage> search({
    required String query,
    required int offset,
    int limit,
    String? listingType,
    String? governorate,
    String? category,
  });

  Future<Listing> fetchById(String id);

  Future<List<Listing>> fetchBySellerId(String sellerId);

  /// Writes a new listing, its photographs and its private pickup address,
  /// then returns the id of the published row.
  ///
  /// Success is only reported once the row exists **and** every photograph has
  /// been stored — a partial publish is never reported as a success.
  ///
  /// [publishId] is the client-generated identity of this publish attempt. The
  /// same value is passed on every retry of the same draft, which is what lets
  /// an implementation return the row an earlier attempt already wrote instead
  /// of creating a second one.
  Future<String> publish(ListingDraft draft, {required String publishId});
}
