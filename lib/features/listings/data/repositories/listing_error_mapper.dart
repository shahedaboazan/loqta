import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/listings/data/datasources/favorites_remote_data_source.dart';
import 'package:loqta/features/listings/data/datasources/listing_remote_data_source.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';

/// Translates Supabase and transport errors into [ListingFailure] copy the
/// screens can show directly.
///
/// Modelled on the existing auth error mapper so the two features behave the
/// same way.
class ListingErrorMapper {
  ListingErrorMapper._();

  static String map(Object error) {
    if (error is PostgrestException) {
      return switch (error.code) {
        '42501' => 'You do not have permission to do that.',
        'PGRST116' || 'P0002' => 'That item is no longer available.',
        '23505' => 'That item is already saved.',
        // The CHECK constraints on `listings` (title length, price versus
        // listing type, currency code, photo count) — the form's own
        // validation is more specific, so this only appears if the two
        // disagree.
        '23514' =>
          'Some listing details were rejected. Check the form and try again.',
        // `listings.seller_id` points at a profile row that is not there yet.
        '23503' => 'Your account is not ready to publish a listing yet.',
        '429' || 'PGRST122' => 'Too many requests. Please try again shortly.',
        _ => _messageOr(
          error.message,
          'Something went wrong. Please try again.',
        ),
      };
    }

    if (error is StorageException) {
      return _messageOr(
        error.message,
        'The photos could not be uploaded. Check your connection and try again.',
      );
    }

    if (error is SocketException) {
      return 'Network error. Check your connection and try again.';
    }

    // The data layer raises StateError with copy that is already safe to show
    // ("A photo could not be uploaded."); `toString()` would prefix it with
    // "Bad state:", so the message is taken directly.
    if (error is StateError) {
      return _messageOr(
        error.message,
        'Something went wrong. Please try again.',
      );
    }

    return _messageOr(
      error.toString(),
      'Something went wrong. Please try again.',
    );
  }

  static String _messageOr(String raw, String fallback) {
    final message = raw.trim();
    if (message.isEmpty || message.toLowerCase() == 'exception')
      return fallback;
    return message;
  }
}

/// Convenience for the data-source specific exceptions above.
String mapListingError(Object error) => switch (error) {
  ListingNotFoundException() => 'That item is no longer available.',
  FavoritesUnavailableException() => 'Sign in to save your favourite items.',
  _ => ListingErrorMapper.map(error),
};
