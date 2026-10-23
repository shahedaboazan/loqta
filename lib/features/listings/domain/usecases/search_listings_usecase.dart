import 'package:loqta/features/listings/domain/entities/listing_page.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';

/// Reads one page of keyword search results.
///
/// The batch size is fixed at four so the Search screen shows
/// "Viewing 4 of 24 listings" on the first pass, matching the approved design.
class SearchListingsUseCase {
  const SearchListingsUseCase(this._repository);

  /// Listings loaded per batch.
  static const int pageSize = 4;

  final ListingRepository _repository;

  Future<ListingPage> call({required String query, required int offset}) =>
      _repository.search(query: query, offset: offset, limit: pageSize);
}
