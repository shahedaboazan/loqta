import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';

/// The "Featured Finds" rows on Home.
class GetFeaturedListingsUseCase {
  const GetFeaturedListingsUseCase(this._repository);

  final ListingRepository _repository;

  Future<List<Listing>> call() => _repository.fetchFeatured();
}
