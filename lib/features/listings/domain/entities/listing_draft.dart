import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:loqta/core/data/listing_form_options.dart';
import 'package:loqta/core/utils/price_formatter.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';

/// Which part of a listing draft a validation failure belongs to.
///
/// One value per field the Create Listing form shows, so the page can put the
/// message under the right control instead of a single banner at the top.
enum ListingField {
  photos,
  title,
  category,
  condition,
  price,
  currency,
  governorate,
  pickupAddress,
  delivery,
  description,
}

/// Why a field failed validation.
///
/// Deliberately language-free: the presentation layer turns a
/// (field, error) pair into copy, so the same draft can be validated without
/// holding an `AppStrings`.
enum ListingFieldError {
  /// The field has no usable value at all.
  required,

  /// Below the minimum length (a title shorter than three characters).
  tooShort,

  /// Above the maximum length (a title over 120 characters, a description
  /// over 1000).
  tooLong,

  /// Present but not usable — an unparseable or non-positive price, or a
  /// currency outside the two the database accepts.
  invalid,

  /// More photographs than the design's five-photo ceiling.
  tooManyPhotos,
}

/// One photograph the user has chosen but not uploaded yet.
///
/// Upload happens once, at publish time, so the Create Listing form and the
/// preview both render straight from memory and a cancelled publish never
/// leaves half a listing's pictures in storage.
class ListingDraftPhoto extends Equatable {
  const ListingDraftPhoto({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  @override
  List<Object?> get props => [bytes, fileName];
}

/// Everything the Create Listing form collects, before anything is written.
///
/// The draft is the single value the form, the Listing Preview screen and the
/// publish call all read from, which is what makes "edit from the preview and
/// come back to a filled form" work without a second source of truth.
class ListingDraft extends Equatable {
  const ListingDraft({
    this.type = ListingType.sale,
    this.photos = const <ListingDraftPhoto>[],
    this.title = '',
    this.category = '',
    this.condition = '',
    this.priceText = '',
    this.currency = 'SYP',
    this.governorate = '',
    this.pickupAddress = '',
    this.deliveryAvailable,
    this.description = '',
  });

  /// Ceiling from the approved design: one to five photographs.
  static const int maxPhotos = 5;

  /// Mirrors the `listings_title_check` constraint in the schema.
  static const int minTitleLength = 3;
  static const int maxTitleLength = 120;

  /// Ceiling for the description field, enforced both by the input formatter
  /// and by this validation.
  static const int maxDescriptionLength = 1000;

  final ListingType type;

  /// Chosen photographs, in the order they will be published. Never longer
  /// than [maxPhotos].
  final List<ListingDraftPhoto> photos;

  final String title;
  final String category;
  final String condition;

  /// Exactly what the price field holds, grouping characters included, so the
  /// form can echo it back unchanged.
  final String priceText;

  final String currency;
  final String governorate;

  /// Exact pickup address. Private: it is written to its own table with
  /// owner-only read access and never appears on a public screen.
  final String pickupAddress;

  /// Null until the user picks "Pickup only" or "Delivery available". There is
  /// deliberately no default, because silently assuming one would publish a
  /// promise the seller never made.
  final bool? deliveryAvailable;

  final String description;

  bool get isDonation => type.isDonation;

  /// The price as a number, or null when [priceText] is not usable.
  double? get price => PriceFormatter.parse(priceText);

  /// The trimmed title, which is what the database stores and checks.
  String get trimmedTitle => title.trim();

  /// The trimmed description.
  String get trimmedDescription => description.trim();

  /// Checks every field and returns the failures, keyed by field.
  ///
  /// The whole form is validated at once so pressing "Continue" reports
  /// everything that is wrong rather than one problem per tap. An empty map
  /// means the draft can be published.
  Map<ListingField, ListingFieldError> validate() {
    final errors = <ListingField, ListingFieldError>{};

    if (photos.isEmpty) {
      errors[ListingField.photos] = ListingFieldError.required;
    } else if (photos.length > maxPhotos) {
      errors[ListingField.photos] = ListingFieldError.tooManyPhotos;
    }

    if (trimmedTitle.isEmpty) {
      errors[ListingField.title] = ListingFieldError.required;
    } else if (trimmedTitle.length < minTitleLength) {
      errors[ListingField.title] = ListingFieldError.tooShort;
    } else if (trimmedTitle.length > maxTitleLength) {
      errors[ListingField.title] = ListingFieldError.tooLong;
    }

    if (category.trim().isEmpty) {
      errors[ListingField.category] = ListingFieldError.required;
    }

    if (condition.trim().isEmpty) {
      errors[ListingField.condition] = ListingFieldError.required;
    }

    // A donation is free: the price and currency fields are hidden, and must
    // stay empty so the database's price/listing-type check holds.
    if (type == ListingType.sale) {
      if (priceText.trim().isEmpty) {
        errors[ListingField.price] = ListingFieldError.required;
      } else if (price == null || price! <= 0) {
        errors[ListingField.price] = ListingFieldError.invalid;
      }

      if (!kListingCurrencies.contains(currency)) {
        errors[ListingField.currency] = ListingFieldError.invalid;
      }
    }

    if (governorate.trim().isEmpty) {
      errors[ListingField.governorate] = ListingFieldError.required;
    }

    if (pickupAddress.trim().isEmpty) {
      errors[ListingField.pickupAddress] = ListingFieldError.required;
    }

    if (deliveryAvailable == null) {
      errors[ListingField.delivery] = ListingFieldError.required;
    }

    if (trimmedDescription.isEmpty) {
      errors[ListingField.description] = ListingFieldError.required;
    } else if (trimmedDescription.length > maxDescriptionLength) {
      errors[ListingField.description] = ListingFieldError.tooLong;
    }

    return errors;
  }

  ListingDraft copyWith({
    ListingType? type,
    List<ListingDraftPhoto>? photos,
    String? title,
    String? category,
    String? condition,
    String? priceText,
    bool clearPrice = false,
    String? currency,
    String? governorate,
    String? pickupAddress,
    bool? deliveryAvailable,
    String? description,
  }) {
    return ListingDraft(
      type: type ?? this.type,
      photos: photos ?? this.photos,
      title: title ?? this.title,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      priceText: clearPrice ? '' : (priceText ?? this.priceText),
      currency: currency ?? this.currency,
      governorate: governorate ?? this.governorate,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    type,
    photos,
    title,
    category,
    condition,
    priceText,
    currency,
    governorate,
    pickupAddress,
    deliveryAvailable,
    description,
  ];
}
