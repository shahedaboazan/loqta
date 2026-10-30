import 'package:flutter/material.dart';

/// A marketplace category.
///
/// [key] is the stable English identifier persisted on a listing. [labelKey] is
/// the matching getter on `AppStrings`, resolved at render time so an Arabic UI
/// shows Arabic category names while the stored data stays language-neutral.
@immutable
class ListingCategory {
  const ListingCategory({
    required this.key,
    required this.labelKey,
    required this.icon,
  });

  final String key;
  final String labelKey;
  final IconData icon;

  /// Resolves the localized label for this category.
  ///
  /// Falls back to the English key for any category that predates a
  /// translation, so an unknown value renders as readable text rather than an
  /// empty row.
  String localize(AppStringsResolver resolver) => resolver(labelKey, key);
}

/// Callback used by [ListingCategory.localize] to turn a label key into
/// displayable text.
typedef AppStringsResolver = String Function(String labelKey, String fallback);

/// The categories Loqta offers, in the order the approved Home design shows
/// them.
///
/// One shared list feeds the Home category strip, the Search category filter
/// and the Create Listing picker, so a category can never be selectable in one
/// place and missing from another.
const List<ListingCategory> kListingCategories = <ListingCategory>[
  ListingCategory(
    key: 'Furniture',
    labelKey: 'categoryFurniture',
    icon: Icons.weekend_outlined,
  ),
  ListingCategory(
    key: 'Electronics',
    labelKey: 'categoryElectronics',
    icon: Icons.laptop_mac_outlined,
  ),
  ListingCategory(
    key: 'Appliances',
    labelKey: 'categoryAppliances',
    icon: Icons.kitchen_outlined,
  ),
  ListingCategory(
    key: 'Clothes',
    labelKey: 'categoryClothes',
    icon: Icons.checkroom_outlined,
  ),
  ListingCategory(
    key: 'Shoes',
    labelKey: 'categoryShoes',
    icon: Icons.directions_walk_outlined,
  ),
  ListingCategory(
    key: 'Children',
    labelKey: 'categoryKids',
    icon: Icons.toys_outlined,
  ),
  ListingCategory(
    key: 'Books',
    labelKey: 'categoryBooks',
    icon: Icons.menu_book_outlined,
  ),
  ListingCategory(
    key: 'Home & Garden',
    labelKey: 'categoryHomeGarden',
    icon: Icons.local_florist_outlined,
  ),
  ListingCategory(
    key: 'Sports',
    labelKey: 'categorySports',
    icon: Icons.sports_soccer_outlined,
  ),
  ListingCategory(
    key: 'Vehicles',
    labelKey: 'categoryVehicles',
    icon: Icons.directions_car_outlined,
  ),
  ListingCategory(
    key: 'Phones',
    labelKey: 'categoryPhones',
    icon: Icons.smartphone_outlined,
  ),
  ListingCategory(
    key: 'Computers',
    labelKey: 'categoryComputers',
    icon: Icons.devices_other_outlined,
  ),
  ListingCategory(
    key: 'Jewelry',
    labelKey: 'categoryJewelry',
    icon: Icons.diamond_outlined,
  ),
  ListingCategory(
    key: 'Toys',
    labelKey: 'categoryToys',
    icon: Icons.toys_outlined,
  ),
  ListingCategory(
    key: 'Women',
    labelKey: 'categoryWomen',
    icon: Icons.woman_outlined,
  ),
  ListingCategory(
    key: 'Bags',
    labelKey: 'categoryBags',
    icon: Icons.work_outline,
  ),
  ListingCategory(
    key: 'Other',
    labelKey: 'categoryOther',
    icon: Icons.category_outlined,
  ),
];

/// Looks up a category by its persisted key. Returns null for an unknown value.
ListingCategory? categoryByKey(String? key) {
  if (key == null || key.isEmpty) return null;
  for (final category in kListingCategories) {
    if (category.key == key) return category;
  }
  return null;
}
