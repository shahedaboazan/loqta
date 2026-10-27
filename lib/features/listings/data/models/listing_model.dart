import 'package:loqta/features/listings/domain/entities/listing.dart';

/// Maps a `listings` row (with its embedded seller and favourite rows) onto the
/// [Listing] entity.
class ListingModel {
  const ListingModel._();

  /// The columns every listing query selects.
  ///
  /// `seller` is PostgREST's embedded resource for the `listings.seller_id`
  /// foreign key, and `favorites` is the embedded `public.favorites` row. RLS
  /// on `favorites` means that embedded array only ever contains the signed-in
  /// user's own rows, which is what makes [Listing.isFavorite] safe to derive
  /// from the payload.
  static const String selectColumns =
      '*, seller:profiles(id, first_name, last_name, avatar_url, created_at), '
      'favorites(user_id)';

  static Listing fromRow(
    Map<String, dynamic> row, {
    String? currentUserId,
    DateTime? savedAt,
  }) {
    final seller = row['seller'] is Map
        ? Map<String, dynamic>.from(row['seller'] as Map)
        : const <String, dynamic>{};

    final favorites = row['favorites'];
    final isFavorite =
        favorites is List &&
        currentUserId != null &&
        favorites.any((row) => row is Map && row['user_id'] == currentUserId);

    final images = row['images'];

    return Listing(
      id: row['id'] as String? ?? '',
      sellerId: row['seller_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      category: row['category'] as String? ?? '',
      condition: row['condition'] as String? ?? '',
      type: ListingType.fromValue(row['listing_type'] as String?),
      price: _toDouble(row['price']),
      currency: row['currency'] as String?,
      deliveryAvailable: row['delivery_available'] as bool?,
      imageUrls: images is List
          ? images.map((value) => value.toString()).toList()
          : const <String>[],
      governorate: row['governorate'] as String? ?? '',
      area: row['area'] as String? ?? '',
      status: ListingStatus.fromValue(row['status'] as String?),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      sellerName: _sellerName(seller, row['seller_id'] as String?),
      sellerAvatarUrl: seller['avatar_url'] as String?,
      sellerMemberSince: DateTime.tryParse(
        seller['created_at'] as String? ?? '',
      )?.toLocal(),
      isFavorite: isFavorite,
      savedAt: savedAt,
    );
  }

  static List<Listing> fromRows(List<dynamic> rows, {String? currentUserId}) =>
      rows
          .whereType<Map>()
          .map(
            (row) => fromRow(
              Map<String, dynamic>.from(row),
              currentUserId: currentUserId,
            ),
          )
          .toList();

  static double? _toDouble(Object? value) => switch (value) {
    num number => number.toDouble(),
    String text => double.tryParse(text),
    _ => null,
  };

  static String? _sellerName(Map<String, dynamic> seller, String? sellerId) {
    final first = (seller['first_name'] as String? ?? '').trim();
    final last = (seller['last_name'] as String? ?? '').trim();
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    // No profile row yet (the trigger has not fired, or the seller signed up
    // before it existed): fall back to a neutral label rather than "null".
    return sellerId == null || sellerId.isEmpty ? null : 'Loqta member';
  }
}
