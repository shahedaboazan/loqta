import 'dart:typed_data';

/// An image the user chose from their device.
///
/// Only the bytes and the file name cross into the domain layer; nothing about
/// the platform picker leaks past this point, which is what lets the Chat screen
/// be tested without a device.
class PickedImage {
  const PickedImage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  bool get isEmpty => bytes.isEmpty;
}

/// Raised when the platform cannot hand over an image.
///
/// A cancelled picker is **not** an error: it returns null instead, so the user
/// changing their mind is never reported as a failure.
class ImagePickException implements Exception {
  const ImagePickException(this.message);

  final String message;

  @override
  String toString() => 'ImagePickException($message)';
}

/// Chooses an image from the device's library.
///
/// Declared in the domain layer and implemented in the data layer so the
/// presentation layer depends on the capability, not on the plugin.
abstract class ImagePickerService {
  /// Returns the chosen image, or null when the user cancelled.
  ///
  /// Throws [ImagePickException] when the platform refused access, has no
  /// photo library, or the file could not be read.
  Future<PickedImage?> pickImage();

  /// Returns every image the user chose in one go, or an empty list when they
  /// cancelled.
  ///
  /// Used by the Create Listing photo step, which offers the multi-select
  /// gallery. The plugin has no built-in ceiling, so the caller decides how
  /// many of the returned images it can actually take rather than having
  /// silently dropped selections reported as success.
  ///
  /// Throws [ImagePickException] under the same conditions as [pickImage].
  Future<List<PickedImage>> pickImages();
}
