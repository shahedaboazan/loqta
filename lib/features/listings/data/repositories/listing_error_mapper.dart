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
        '429' || 'PGRST122' => 'Too many requests. Please try again shortly.',
        _ => _messageOr(
          error.message,
          'Something went wrong. Please try again.',
        ),
      };
    }

    if (error is SocketException) {
      return 'Network error. Check your connection and try again.';
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
