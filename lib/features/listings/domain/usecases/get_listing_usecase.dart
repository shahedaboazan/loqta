import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';

/// Reads a single listing for the Listing Details screen.
class GetListingUseCase {
  const GetListingUseCase(this._repository);

  final ListingRepository _repository;

  Future<Listing> call(String id) => _repository.fetchById(id);
}
