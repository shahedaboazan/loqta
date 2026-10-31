import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/listings/data/models/listing_model.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/entities/listing_draft.dart';
import 'package:loqta/features/listings/domain/entities/listing_page.dart';
import 'package:flutter/foundation.dart';

/// Thrown when a listing id has no matching row, or the caller cannot read it.
///
/// Declared next to the only code that throws it; `mapListingError` turns it
/// into the "no longer available" copy the screens show.
class ListingNotFoundException implements Exception {
  const ListingNotFoundException();

  @override
  String toString() => 'ListingNotFoundException';
}

/// Thin wrapper around the `public.listings` table.
///
/// Mirrors the shape of the existing auth data source: nothing above this file
/// touches the Supabase SDK.
class ListingRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<ListingPage> search({
    required String query,
    required int offset,
    required int limit,
    String? listingType,
    String? governorate,
    String? category,
  }) async {
    final term = _sanitize(query);

    // Pattern for ILIKE.
    final pattern = term.isEmpty ? null : '%$term%';

    var queryBuilder = _client
        .from('listings')
        .select(ListingModel.selectColumns)
        .eq('status', 'available');

    // Add filter: Text search (title or description or category)
    if (pattern != null) {
      queryBuilder = queryBuilder.or(
        'title.ilike.$pattern,description.ilike.$pattern,category.ilike.$pattern',
      );
    }

    // Add filter: Listing Type
    if (listingType != null && listingType != 'all') {
      queryBuilder = queryBuilder.eq('listing_type', listingType);
    }

    // Add filter: Governorate
    if (governorate != null && governorate != 'all') {
      queryBuilder = queryBuilder.eq('governorate', governorate);
    }

    // Add filter: Category
    if (category != null && category != 'all') {
      queryBuilder = queryBuilder.eq('category', category);
    }

    final response = await queryBuilder
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    final rows = response.data.whereType<Map>().toList();

    return ListingPage(
      items: ListingModel.fromRows(rows, currentUserId: _currentUserId),
      total: response.count,
      offset: offset,
    );
  }

  Future<List<Listing>> fetchFeatured({int limit = 6}) async {
    final rows = await _client
        .from('listings')
        .select(ListingModel.selectColumns)
        .eq('status', 'available')
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    return ListingModel.fromRows(rows, currentUserId: _currentUserId);
  }

  Future<Listing> fetchById(String id) async {
    final row = await _client
        .from('listings')
        .select(ListingModel.selectColumns)
        .eq('id', id)
        .maybeSingle();

    if (row == null) {
      throw const ListingNotFoundException();
    }

    return ListingModel.fromRow(row, currentUserId: _currentUserId);
  }

  Future<List<Listing>> fetchBySellerId(String sellerId) async {
    final rows = await _client
        .from('listings')
        .select(ListingModel.selectColumns)
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    return ListingModel.fromRows(rows, currentUserId: _currentUserId);
  }

  /// Strips the characters PostgREST's `or(...)` grammar treats as structure, so
  /// a query like `sofa, (rare)` cannot change the shape of the filter.
  static String _sanitize(String value) => value
      .replaceAll(RegExp(r'[,()%*\\]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // ---------------------------------------------------------------------
  // Publishing
  // ---------------------------------------------------------------------

  /// Public bucket holding listing photography, so `listings.images` can carry
  /// plain URLs that `Image.network` renders without a signed request.
  static const String imagesBucket = 'listing-images';

  /// Uploads every photograph, then writes the listing row and its private
  /// pickup address through the `publish_listing` RPC.
  ///
  /// The order matters: photographs first, database second. A listing row can
  /// never reference a photo that failed to upload, and nothing is reported as
  /// published until both steps have completed.
  ///
  /// [publishId] doubles as the listing id and as the photo folder, so a retry
  /// of the same attempt reuses the same identity rather than adding a second
  /// listing.
  Future<String> publish(
    ListingDraft draft, {
    required String publishId,
  }) async {
    if (_currentUserId == null) {
      throw StateError('Sign in to publish a listing.');
    }

    final objectPaths = <String>[];
    final imageUrls = <String>[];
    // PUBLISH DEBUG
    debugPrint('[PUBLISH DATA] Started');
    debugPrint('[PUBLISH DATA] User authenticated: ${_currentUserId != null}');
    debugPrint('[PUBLISH DATA] Photos count: ${draft.photos.length}');
    debugPrint('[PUBLISH DATA] Listing ID: $publishId');

    try {
      for (var index = 0; index < draft.photos.length; index++) {
        final photo = draft.photos[index];
        final objectPath =
            'listings/$publishId/$index-${_randomToken()}.'
            '${_extensionFor(photo.fileName)}';

        // A fresh name per attempt: two retries can never collide on the same
        // object key, so an upload never fails because the key is taken.
        debugPrint(
          '[PUBLISH DATA] Uploading photo ${index + 1}/${draft.photos.length}',
        );
        final stored = await _client.storage
            .from(imagesBucket)
            .uploadBinary(objectPath, photo.bytes);

        if (stored.isEmpty) {
          throw StateError('A photo could not be uploaded.');
        }
        debugPrint('[PUBLISH DATA] Photo ${index + 1} uploaded successfully');
        objectPaths.add(objectPath);
        imageUrls.add(
          _client.storage.from(imagesBucket).getPublicUrl(objectPath),
        );
      }
    } catch (error, stackTrace) {
      // The database has not been touched yet, so everything uploaded so far
      // is unreachable garbage. The owner-only delete policy removes it.
      debugPrint('[PUBLISH DATA] PHOTO UPLOAD ERROR: $error');
      debugPrint('[PUBLISH DATA] PHOTO UPLOAD STACK: $stackTrace');
      await _discard(objectPaths);
      rethrow;
    }

    try {
      debugPrint('[PUBLISH DATA] Starting publish_listing RPC');

      final response = await _client.rpc(
        'publish_listing',
        params: {
          'p_listing_id': publishId,
          'p_title': draft.trimmedTitle,
          'p_description': draft.trimmedDescription,
          'p_category': draft.category.trim(),
          'p_condition': draft.condition.trim(),
          'p_listing_type': draft.type.isDonation ? 'donation' : 'sale',
          'p_price': draft.isDonation ? null : draft.price,
          'p_currency': draft.isDonation ? null : draft.currency,
          'p_images': imageUrls,
          'p_governorate': draft.governorate.trim(),
          'p_delivery_available': draft.deliveryAvailable,
          'p_pickup_address': draft.pickupAddress.trim(),
        },
      );

      debugPrint('[PUBLISH DATA] RPC completed. Response: $response');
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('[PUBLISH DATA] RPC ERROR: ${error.message}');
      debugPrint('[PUBLISH DATA] RPC CODE: ${error.code}');
      debugPrint('[PUBLISH DATA] RPC DETAILS: ${error.details}');
      debugPrint('[PUBLISH DATA] RPC HINT: ${error.hint}');
      debugPrint('[PUBLISH DATA] RPC STACK: $stackTrace');

      await _discard(objectPaths);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[PUBLISH DATA] NON-POSTGREST ERROR: $error');
      debugPrint('[PUBLISH DATA] STACK: $stackTrace');
      rethrow;
    } on PostgrestException {
      // The server rejected the write, so its transaction rolled back and no
      // row can reference these objects. Deleting them keeps the bucket clean.
      await _discard(objectPaths);
      rethrow;
    }
    // Anything else — a dropped connection, a timeout — leaves the outcome
    // unknown: the row may already exist. The objects are deliberately kept,
    // because deleting them could strip the photos off a listing that did
    // publish. The retry path recognises the same id and finishes the job.

    return publishId;
  }

  /// Best-effort removal of objects whose publish did not complete.
  Future<void> _discard(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(imagesBucket).remove(paths);
    } catch (_) {
      // A leftover object must never mask the original failure the caller
      // needs to see, so cleanup failures are swallowed.
    }
  }

  static final Random _random = Random.secure();

  static String _randomToken() => List<String>.generate(
    8,
    (_) => '0123456789abcdef'[_random.nextInt(16)],
  ).join();

  /// The file extension the storage content type is derived from, falling back
  /// to JPEG when a name carries none or carries something unexpected.
  static String _extensionFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final extension = dot == -1
        ? ''
        : fileName.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension) ? extension : 'jpg';
  }
}
