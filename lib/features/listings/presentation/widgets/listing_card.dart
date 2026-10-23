import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';

/// The listing tile used by the Home grid and the Search results grid.
///
/// Transcribed from `design_drafts/screens/10_home.png` and
/// `design_drafts/screens/11_search.png`: a photo with the sale/donation badge
/// and the favourite heart on top, then title, price, condition and the
/// governorate/area line.
///
/// The card renders real listing data. When a listing has no photograph it
/// falls back to a brand-tinted panel with its category glyph, which is what
/// the reference showed before listing photography existed.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onFavoriteTap,
  });

  /// Height of the listing thumbnail.
  static const double thumbnailHeight = 126;

  /// Total card height: thumbnail plus the title, price, condition and
  /// location rows. Both are constant, so the grid cannot overflow on a wide
  /// viewport or collapse on a narrow one.
  static const double cardExtent = 228;

  final Listing listing;
  final VoidCallback onTap;

  /// When null the heart is decorative only. Pass it to make the heart toggle
  /// the favourite state.
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final accent = listing.isDonation
        ? LoqtaColors.accentCyan
        : LoqtaColors.primary;
    final price = listing.formattedPrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: LoqtaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LoqtaColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: thumbnailHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Thumbnail(listing: listing, accent: accent),
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        listing.isDonation ? 'Donation' : 'For Sale',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _FavoriteHeart(
                      isFavorite: listing.isFavorite,
                      onTap: onFavoriteTap,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LoqtaColors.headingPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          price ?? 'Free',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ),
                      // Donations are free, so the currency suffix only
                      // applies to priced listings.
                      if (price != null) ...[
                        const SizedBox(width: 5),
                        Text(
                          'SYP',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const _ConditionDot(),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          listing.condition,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LoqtaColors.textSecondary,
                            fontSize: 9.5,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 11,
                        color: LoqtaColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LoqtaColors.textTertiary,
                            fontSize: 9.5,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listing photography, or the category glyph when there is no image.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.listing, required this.accent});

  final Listing listing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final url = listing.imageUrls.isEmpty ? null : listing.imageUrls.first;

    if (url == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.10),
              accent.withValues(alpha: 0.22),
            ],
          ),
        ),
        child: Icon(
          listing.isDonation ? Icons.redeem_outlined : Icons.chair_outlined,
          size: 34,
          color: accent.withValues(alpha: 0.55),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      // A dead image URL must not leave an empty tile: fall back to the same
      // tinted panel the no-photo case uses.
      errorBuilder: (_, _, _) => Container(
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.12)),
        child: Icon(
          listing.isDonation ? Icons.redeem_outlined : Icons.chair_outlined,
          size: 30,
          color: accent.withValues(alpha: 0.5),
        ),
      ),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(color: accent.withValues(alpha: 0.08)),
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({required this.isFavorite, this.onTap});

  final bool isFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 14,
            color: isFavorite
                ? const Color(0xFFE5484D)
                : LoqtaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// The small green dot that precedes a listing's condition.
class _ConditionDot extends StatelessWidget {
  const _ConditionDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFF9BCB5E),
        shape: BoxShape.circle,
      ),
    );
  }
}
