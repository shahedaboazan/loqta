import 'package:loqta/core/localization/app_strings.dart';
import 'package:loqta/features/listings/domain/entities/listing_draft.dart';

/// Resolves the localized message for a failed draft field.
///
/// The validation itself is language-free (it reports the kind of failure), the
/// copy is resolved here so the presentation layer never hardcodes strings it
/// is meant to localise.
String createListingFieldErrorText(
  AppStrings strings,
  ListingField field,
  ListingFieldError error,
) {
  switch (field) {
    case ListingField.photos:
      return error == ListingFieldError.tooManyPhotos
          ? strings.photoLimit
          : strings.photoRequired;
    case ListingField.title:
      switch (error) {
        case ListingFieldError.tooLong:
          return strings.titleTooLong;
        case ListingFieldError.tooShort:
          return strings.titleTooShort;
        case ListingFieldError.required:
        case ListingFieldError.invalid:
        case ListingFieldError.tooManyPhotos:
          return strings.requiredField;
      }
    case ListingField.description:
      return error == ListingFieldError.tooLong
          ? strings.descriptionTooLong
          : strings.requiredField;
    case ListingField.price:
      return error == ListingFieldError.invalid
          ? strings.priceInvalid
          : strings.enterPrice;
    case ListingField.currency:
      return strings.selectCurrency;
    case ListingField.category:
      return strings.selectCategory;
    case ListingField.condition:
      return strings.selectCondition;
    case ListingField.governorate:
      return strings.selectGovernorate;
    case ListingField.delivery:
      return strings.selectDeliveryOption;
    case ListingField.pickupAddress:
      return strings.requiredField;
  }
}
