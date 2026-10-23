import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:loqta/features/chat/domain/services/image_picker_service.dart';

/// [ImagePickerService] backed by the `image_picker` plugin.
///
/// Only the gallery is used. The camera and video sources are deliberately not
/// offered, so the app needs no camera or microphone usage description and
/// cannot record anything.
///
/// The plugin never receives the user's file directly: it returns an [XFile],
/// which is read into memory here and handed on as bytes. Nothing leaves the
/// device until the bytes are uploaded through the chat data layer.
class ImagePickerDataSource implements ImagePickerService {
  ImagePickerDataSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Longest edge kept. A chat attachment does not need a 12 MP original, and
  /// uploading one would make the send slow on a mobile connection.
  static const double _maxEdge = 1920;

  @override
  Future<PickedImage?> pickImage() async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxEdge,
        maxHeight: _maxEdge,
        imageQuality: 85,
      );
    } on PlatformException catch (error) {
      throw ImagePickException(_messageFor(error));
    } on MissingPluginException {
      // The plugin is not registered on this platform build.
      throw const ImagePickException(
        'Photos are not available on this platform.',
      );
    } catch (_) {
      throw const ImagePickException(
        'Photos could not be opened on this device.',
      );
    }

    // Cancelled: the user closed the picker without choosing anything.
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImagePickException('That photo could not be read.');
    }

    return PickedImage(bytes: bytes, fileName: file.name);
  }

  /// Maps a platform failure onto copy that says what actually went wrong.
  ///
  /// A denied permission is the common case, and it is reported as such rather
  /// than as a generic error, so the user knows to retry after allowing access.
  static String _messageFor(PlatformException error) {
    final code = error.code.toLowerCase();

    if (code.contains('denied') || code.contains('permission')) {
      return 'Photo access was denied. Allow it in Settings to attach a photo.';
    }
    if (code.contains('unavailable') || code.contains('unsupported')) {
      return 'Photos are not available on this device.';
    }

    final details = error.message?.trim() ?? '';
    if (details.isEmpty || details.toLowerCase() == 'exception') {
      return 'That photo could not be selected.';
    }
    return details;
  }
}
