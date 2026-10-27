import 'package:loqta/features/listings/domain/entities/listing_draft.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';

/// Publishes a validated listing draft.
///
/// Kept as a use case so the Create Listing BLoC depends on an action rather
/// than on the repository's read surface, matching the other listing use cases.
class PublishListingUseCase {
  const PublishListingUseCase(this._repository);

  final ListingRepository _repository;

  /// Returns the id of the published listing once the row and all of its
  /// photographs exist.
  Future<String> call(ListingDraft draft, {required String publishId}) =>
      _repository.publish(draft, publishId: publishId);
}
