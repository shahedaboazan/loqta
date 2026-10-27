import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';

class GetMyListingsUseCase {
  GetMyListingsUseCase(this._repository);
  final ListingRepository _repository;
  Future<List<Listing>> call(String sellerId) => _repository.fetchBySellerId(sellerId);
}
