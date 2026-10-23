import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/listings/data/models/listing_model.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/entities/listing_page.dart';

/// Thrown when a listing id has no matching row, or the caller cannot read it.
///
/// Declared next to the only code that throws it; `mapListingError` turns it
/// into the "no longer available" copy the screens show.
class ListingNotFoundException implements Exception {
  const ListingNotFoundException();

  @override
  String toString() => 'ListingNotFoundException';
}

/// Thin wrapper around the `public.listings` table.
///
/// Mirrors the shape of the existing auth data source: nothing above this file
/// touches the Supabase SDK.
class ListingRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Posts a `count=exact` preference so `response.count` is the total number
  /// of matches, not the size of the page.
  Future<ListingPage> search({
    required String query,
    required int offset,
    required int limit,
  }) async {
    final term = _sanitize(query);
    if (term.isEmpty) {
      return const ListingPage(items: [], total: 0, offset: 0);
    }

    final pattern = '%$term%';

    // `created_at` then `id` is a total order: every row has a unique id, so a
    // row can never appear in two batches or fall between them even when many
    // listings share a timestamp.
    final response = await _client
        .from('listings')
        .select(ListingModel.selectColumns)
        .eq('status', 'active')
        .or(
          'title.ilike.$pattern,description.ilike.$pattern,category.ilike.$pattern',
        )
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    final rows = response.data.whereType<Map>().toList();

    return ListingPage(
      items: ListingModel.fromRows(rows, currentUserId: _currentUserId),
      total: response.count,
      offset: offset,
    );
  }

  Future<List<Listing>> fetchFeatured({int limit = 6}) async {
    final rows = await _client
        .from('listings')
        .select(ListingModel.selectColumns)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    return ListingModel.fromRows(rows, currentUserId: _currentUserId);
  }

  Future<Listing> fetchById(String id) async {
    final row = await _client
        .from('listings')
        .select(ListingModel.selectColumns)
        .eq('id', id)
        .maybeSingle();

    if (row == null) {
      throw const ListingNotFoundException();
    }

    return ListingModel.fromRow(row, currentUserId: _currentUserId);
  }

  /// Strips the characters PostgREST's `or(...)` grammar treats as structure, so
  /// a query like `sofa, (rare)` cannot change the shape of the filter.
  static String _sanitize(String value) => value
      .replaceAll(RegExp(r'[,()%*\\]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
