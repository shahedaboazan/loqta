import 'package:equatable/equatable.dart';

import 'package:loqta/features/listings/domain/entities/listing.dart';

/// One page of listings plus the total number of matches for the query.
///
/// [total] comes from PostgREST's exact row count, which is what the Search
/// screen renders as "24 results found" and "Viewing 4 of 24 listings".
class ListingPage extends Equatable {
  const ListingPage({
    required this.items,
    required this.total,
    required this.offset,
  });

  final List<Listing> items;

  /// Total number of listings matching the query, not just this page.
  final int total;

  /// Offset this page was read from, so the caller can advance it.
  final int offset;

  bool get isEmpty => items.isEmpty;

  /// True when every match has already been displayed.
  bool get hasReachedEnd => offset + items.length >= total;

  @override
  List<Object?> get props => [items, total, offset];
}
