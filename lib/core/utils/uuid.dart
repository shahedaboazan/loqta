import 'dart:math';

/// Generates a random (version 4) UUID.
///
/// The Create Listing flow needs an identity *before* the row exists: photo
/// objects are filed under `listings/<uuid>/…` and the same id is passed to
/// the `publish_listing` RPC, which is what makes a retry return the listing
/// the first attempt already wrote instead of creating a second one.
///
/// The id is generated once per publish attempt and reused on every retry, so
/// two concurrent taps can never produce two listings.
String generateUuidV4([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));

  // Version 4 (random) and variant 10xx, per RFC 4122.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
  final parts = hex.toList();
  return [
    parts.sublist(0, 4).join(),
    parts.sublist(4, 6).join(),
    parts.sublist(6, 8).join(),
    parts.sublist(8, 10).join(),
    parts.sublist(10, 16).join(),
  ].join('-');
}
