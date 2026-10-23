import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/entities/listing_page.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';

/// In-memory [ListingRepository] for widget tests.
///
/// `main.dart` registers the real repository above `MaterialApp`, and
/// `HomeView` reads it in `FeaturedListingsBloc`, so every test that pumps the
/// Home screen (or the `AuthGate` that routes to it) has to provide one. This
/// fake stands in for that registration without touching production code.
class FakeListingRepository implements ListingRepository {
  FakeListingRepository({this.featured = const [], this.all = const []});

  /// Rows returned by [fetchFeatured], in order.
  final List<Listing> featured;

  /// The full catalogue. [search] matches against it and [fetchById] reads
  /// from it, which is what lets the Search and Listing Details screens be
  /// exercised against real entities.
  final List<Listing> all;

  /// How many times [fetchFeatured] ran, so a test can assert the grid was
  /// actually driven by the repository rather than by empty chrome.
  int featuredCalls = 0;

  @override
  Future<List<Listing>> fetchFeatured({int limit = 6}) async {
    featuredCalls++;
    return featured.take(limit).toList();
  }

  @override
  Future<ListingPage> search({
    required String query,
    required int offset,
    int limit = 4,
  }) async {
    final term = query.trim().toLowerCase();
    final matches = all
        .where(
          (listing) =>
              listing.title.toLowerCase().contains(term) ||
              listing.description.toLowerCase().contains(term) ||
              listing.category.toLowerCase().contains(term),
        )
        .toList();

    return ListingPage(
      items: matches.skip(offset).take(limit).toList(),
      total: matches.length,
      offset: offset,
    );
  }

  @override
  Future<Listing> fetchById(String id) async {
    final listing = all.where((row) => row.id == id).firstOrNull;
    if (listing == null) {
      throw StateError('FakeListingRepository has no row for "$id".');
    }
    return listing;
  }
}

/// The catalogue the Search and Listing Details screens are driven from.
///
/// Two priced rows and two donations, matching what the Home design shows.
List<Listing> featuredFixtureListings() => [
  _listing(
    id: 'l1',
    title: 'Modern Fabric Sofa',
    price: 1500000,
    type: ListingType.sale,
  ),
  _listing(
    id: 'l2',
    title: 'Vintage Wooden Desk',
    price: 350000,
    type: ListingType.sale,
  ),
  _listing(id: 'l3', title: 'Kids Bicycle', type: ListingType.donation),
  _listing(id: 'l4', title: 'Winter Jacket', type: ListingType.donation),
];

/// The full catalogue behind [featuredFixtureListings], so a keyword search has
/// something to match against.
List<Listing> listingFixtureCatalogue() => featuredFixtureListings();

/// One saved row for the Favorites screen: a donation, saved recently, so the
/// "Saved ... ago" caption reads from the favourite rather than the listing.
Listing favoriteFixtureListing() {
  final listing = _listing(
    id: 'l3',
    title: 'Kids Bicycle',
    type: ListingType.donation,
  );
  // Two extra hours so the relative caption reads a flat "4d ago" instead of
  // flipping to "3d ago" the moment a few minutes elapse between this line and
  // the render.
  return listing.copyWith(
    savedAt: DateTime.now().subtract(const Duration(days: 4, hours: 2)),
  );
}

Listing _listing({
  required String id,
  required String title,
  required ListingType type,
  double? price,
}) {
  return Listing(
    id: id,
    sellerId: 'seller-$id',
    title: title,
    description: 'A pre-owned $title listed by a Loqta member.',
    category: 'Furniture',
    condition: 'Like New',
    type: type,
    price: price,
    // No photography: the card falls back to its category glyph, which is the
    // path the reference design shows for an unphotographed listing.
    imageUrls: const [],
    governorate: 'Damascus',
    area: '',
    status: ListingStatus.active,
    createdAt: DateTime(2026, 1, 1),
  );
}
