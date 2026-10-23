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
}
