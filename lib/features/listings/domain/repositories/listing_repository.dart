import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/entities/listing_page.dart';

/// Reads listing data.
///
/// Deliberately has no filter parameters: the approved Search design has a
/// single keyword input and no filter affordances.
abstract class ListingRepository {
  /// The "Featured Finds" rows on Home.
  Future<List<Listing>> fetchFeatured({int limit = 6});

  /// One page of listings whose title, description or category contains
  /// [query].
  ///
  /// Pagination is server-side: the data source reads exactly [limit] rows
  /// starting at [offset] and orders by `created_at desc, id desc` so batches
  /// never overlap or skip a listing.
  Future<ListingPage> search({
    required String query,
    required int offset,
    int limit,
  });

  Future<Listing> fetchById(String id);
}
