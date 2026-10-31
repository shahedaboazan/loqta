import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/data/listing_categories.dart';
/// The category entries in the horizontal "Categories" strip on Home.
///
/// The approved Home design shows a fixed decorative strip and the Search screen
/// has no filter affordances, so these are navigation chrome rather than a
/// queryable category list.
// class HomeCategory {
//   const HomeCategory({required this.label, required this.icon});

//   final String label;
//   final IconData icon;
// }

// const List<HomeCategory> kHomeCategories = [
//   HomeCategory(label: 'Furniture', icon: Icons.weekend_outlined),
//   HomeCategory(label: 'Electronics', icon: Icons.laptop_mac_outlined),
//   HomeCategory(label: 'Appliances', icon: Icons.kitchen_outlined),
//   HomeCategory(label: 'Clothes', icon: Icons.checkroom_outlined),
//   HomeCategory(label: 'Shoes', icon: Icons.directions_walk_outlined),
//   HomeCategory(label: 'Children', icon: Icons.toys_outlined),
// ];

/// The rounded search bar on Home.
///
/// It is an entry point only: tapping it opens the Search screen, where the
/// keyword is typed and results appear. It is not an editable field, so Home
/// has no search state of its own.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 18,
                  color: LoqtaColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search for items...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LoqtaText.fieldHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "For Sale" / "For Donation" promo cards.
class HomePromoCard extends StatelessWidget {
  const HomePromoCard({
    super.key,
    required this.icon,
    required this.pillLabel,
    required this.title,
    required this.caption,
    required this.accent,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String pillLabel;
  final String title;
  final String caption;
  final Color accent;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 17, color: accent),
                  ),
                  const SizedBox(width: 6),
                  // Flexible so a wide fallback font ellipsises the pill
                  // rather than overflowing the card.
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        pillLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: LoqtaColors.headingPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: LoqtaText.family,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LoqtaColors.textSecondary,
                  fontSize: 10,
                  fontFamily: LoqtaText.family,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section heading with an optional trailing action, e.g.
/// "Categories ... See All".
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.pill,
    this.trailingCaption,
  });

  final String title;
  final Widget? trailing;
  final String? pill;
  final String? trailingCaption;

  @override
  Widget build(BuildContext context) {
    // spaceBetween lays the children out at their natural size and puts the
    // slack between them. Flexible runs only shrink (with an ellipsis) when the
    // row genuinely cannot fit, which a Spacer or a second flexible sibling
    // would cause even when there is room.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LoqtaColors.headingPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: LoqtaText.family,
            ),
          ),
        ),
        if (pill != null)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: LoqtaColors.pillSurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                pill!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LoqtaColors.primary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: LoqtaText.family,
                ),
              ),
            ),
          ),
        if (trailingCaption != null)
          Flexible(
            child: Text(
              trailingCaption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: LoqtaText.caption,
            ),
          ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

/// The horizontal category strip.

class HomeCategoryStrip extends StatelessWidget {
  const HomeCategoryStrip({
    super.key,
    required this.onSelected,
  });

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = kListingCategories.take(6).toList();

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];

          return GestureDetector(
            onTap: () => onSelected(category.key),
            child: Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: LoqtaColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LoqtaColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: LoqtaColors.surfaceMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category.icon,
                      size: 15,
                      color: LoqtaColors.primary,
                    ),
                  ),
                  Text(
                    category.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LoqtaColors.textPrimary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
