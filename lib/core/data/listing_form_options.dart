import 'package:loqta/core/localization/app_strings.dart';

/// The four conditions a listing may carry, in the order the approved Create
/// Listing design shows them as chips.
///
/// The *stored* value is the English label, matching the free-text `condition`
/// column and the copy the Listing Details screen already renders. Only the
/// chip a user taps is localized, so a listing published in Arabic still reads
/// the same everywhere the value is displayed.
const List<String> kListingConditionValues = <String>[
  'New',
  'Like New',
  'Good Condition',
  'Fair',
];

/// Resolves a stored condition value to the active language's label, falling
/// back to the stored value for anything written before this list existed.
String listingConditionLabel(AppStrings strings, String value) =>
    switch (value) {
      'New' => strings.newItem,
      'Like New' => strings.likeNew,
      'Good Condition' => strings.goodCondition,
      'Fair' => strings.conditionFair,
      _ => value,
    };

/// The currencies the Price field offers, in the order the design shows them.
///
/// Syria trades in Syrian pounds and US dollars; nothing else is offered so a
/// listing can never carry a code the `listings_price_matches_type` check
/// rejects.
const List<String> kListingCurrencies = <String>['SYP', 'USD'];
