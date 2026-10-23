import 'package:loqta/features/listings/data/datasources/favorites_remote_data_source.dart';
import 'package:loqta/features/listings/data/repositories/listing_error_mapper.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._dataSource);

  final FavoritesRemoteDataSource _dataSource;

  @override
  Future<List<Listing>> fetchFavoriteListings() =>
      _guard(_dataSource.fetchFavoriteListings);

  @override
  Future<bool> toggle(String listingId) =>
      _guard(() => _dataSource.toggle(listingId));

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
