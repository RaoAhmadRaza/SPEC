import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// The long edge and quality a household photo is worth keeping at. Left at
/// full resolution, a hundred photos is hundreds of megabytes for no gain.
const double _maxDimension = 2048;
const int _quality = 85;

/// Getting a photo, from wherever the user can actually get one.
///
/// Deliberately the system camera rather than an in-app preview: screen 11's
/// frame is an empty tile in the design, so a live feed would be inventing
/// something the design does not show, and the platform picker brings its own
/// permission prompt, resizing and orientation handling with it.
class PhotoCapture {
  PhotoCapture([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Opens the camera, falling back to the photo library when the camera is
  /// unavailable or refused.
  ///
  /// Refusing the camera is never a dead end: the library picker needs no
  /// permission on either platform, so a user who says no can still finish.
  Future<File?> takePhoto() async {
    try {
      final shot = await _pick(ImageSource.camera);
      if (shot != null) return shot;
    } on PlatformException {
      return pickFromLibrary();
    }
    return null;
  }

  Future<File?> pickFromLibrary() async {
    try {
      return await _pick(ImageSource.gallery);
    } on PlatformException {
      return null;
    }
  }

  Future<File?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
    );
    return file == null ? null : File(file.path);
  }
}
