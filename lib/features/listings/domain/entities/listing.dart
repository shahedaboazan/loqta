import 'package:equatable/equatable.dart';

import 'package:loqta/core/utils/price_formatter.dart';

/// Whether a listing is priced or given away free.
enum ListingType {
  sale,
  donation;

  static ListingType fromValue(String? value) =>
      value == 'donation' ? ListingType.donation : ListingType.sale;

  bool get isDonation => this == ListingType.donation;
}

/// Lifecycle of a listing, used by the "listing status update" notification.
enum ListingStatus {
  available,
  reserved,
  sold,
  donated;

  static ListingStatus fromValue(String? value) => switch (value) {
  'available' => ListingStatus.available,
  'reserved' => ListingStatus.reserved,
  'sold' => ListingStatus.sold,
  'donated' => ListingStatus.donated,
  _ => ListingStatus.available,
};
}

/// A marketplace listing.
///
/// Free of any Supabase or Flutter type so the presentation layer can render
/// it without knowing where it came from.
///
/// The entity deliberately carries **no pickup address**. Only [governorate]
/// and [area] are public, per the product restrictions in
/// `design_spec.md`.
class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.type,
    required this.price,
    required this.imageUrls,
    required this.governorate,
    required this.area,
    required this.status,
    required this.createdAt,
    this.currency,
    this.deliveryAvailable,
    this.sellerName,
    this.sellerAvatarUrl,
    this.sellerMemberSince,
    this.isFavorite = false,
    this.savedAt,
  });

  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String category;
  final String condition;
  final ListingType type;
  final double? price;

  /// Currency shown next to [price] — `SYP` or `USD`. Null for a donation,
  /// which has no price to qualify, and for rows written before the Create
  /// Listing flow asked for one.
  final String? currency;

  /// Whether the seller offers delivery as well as pickup.
  ///
  /// The Create Listing form forces an explicit choice, so a newly published
  /// row is never null; the nullable type only exists for rows that predate
  /// the question.
  final bool? deliveryAvailable;

  /// Listing photography. May be empty, in which case the UI falls back to the
  /// category glyph used by the Home grid.
  final List<String> imageUrls;

  /// Public location only — never an exact pickup address.
  final String governorate;
  final String area;

  final ListingStatus status;
  final DateTime createdAt;

  final String? sellerName;
  final String? sellerAvatarUrl;
  final DateTime? sellerMemberSince;

  /// Whether the authenticated user has favourited this listing. Null-free
  /// because the UI always renders a filled or outlined heart.
  final bool isFavorite;

  /// When *this user* saved the listing, taken from the `favorites` row rather
  /// than [createdAt].
  ///
  /// The Favorites screen says "Saved 2d ago", which is a statement about the
  /// favourite, not about when the item was listed. Null wherever the listing
  /// was not read through the favourites table.
  final DateTime? savedAt;

  bool get isDonation => type.isDonation;

  /// "Damascus - Mazzeh", the governorate/area pair shown on cards and details.
  String get locationLabel {
    final parts = <String>[
      if (governorate.trim().isNotEmpty) governorate.trim(),
      if (area.trim().isNotEmpty) area.trim(),
    ];
    return parts.join(' - ');
  }

  /// Grouped thousands, e.g. `1,500,000`. Donations return null so callers
  /// render "Free" instead.
  String? get formattedPrice {
    final value = price;
    if (isDonation || value == null) return null;
    return PriceFormatter.groupAmount(value);
  }

  /// The currency label shown beside [formattedPrice].
  ///
  /// Rows that predate the currency column read as `SYP`, which is what every
  /// listing in the original catalogue used.
  String get currencyLabel {
    final code = currency?.trim();
    return code == null || code.isEmpty ? 'SYP' : code;
  }

  Listing copyWith({
    bool? isFavorite,
    String? sellerName,
    String? sellerAvatarUrl,
    DateTime? savedAt,
  }) {
    return Listing(
      id: id,
      sellerId: sellerId,
      title: title,
      description: description,
      category: category,
      condition: condition,
      type: type,
      price: price,
      currency: currency,
      deliveryAvailable: deliveryAvailable,
      imageUrls: imageUrls,
      governorate: governorate,
      area: area,
      status: status,
      createdAt: createdAt,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatarUrl: sellerAvatarUrl ?? this.sellerAvatarUrl,
      sellerMemberSince: sellerMemberSince,
      isFavorite: isFavorite ?? this.isFavorite,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  List<Object?> get props => [id, sellerId, title, isFavorite, status, savedAt];
}
