import 'package:loqta/features/listings/data/datasources/listing_remote_data_source.dart';
import 'package:loqta/features/listings/data/repositories/listing_error_mapper.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/entities/listing_page.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';

class ListingRepositoryImpl implements ListingRepository {
  ListingRepositoryImpl(this._dataSource);

  final ListingRemoteDataSource _dataSource;

  @override
  Future<List<Listing>> fetchFeatured({int limit = 6}) =>
      _guard(() => _dataSource.fetchFeatured(limit: limit));

  @override
  Future<ListingPage> search({
    required String query,
    required int offset,
    int limit = 4,
  }) => _guard(
    () => _dataSource.search(query: query, offset: offset, limit: limit),
  );

  @override
  Future<Listing> fetchById(String id) =>
      _guard(() => _dataSource.fetchById(id));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ListingFailure {
      rethrow;
    } catch (error) {
      throw ListingFailure(mapListingError(error));
    }
  }
}
