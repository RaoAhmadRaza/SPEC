import 'dart:io';

import 'package:flutter/widgets.dart';

/// The largest box a stored photo is drawn into outside the fullscreen
/// viewer: Home's 170pt card and screen 03's ~233×158 main slot.
const double kPhotoEdgeLarge = 240;

/// Search rows (54pt) and Collections rows (58pt).
const double kPhotoEdgeSmall = 60;

// ponytail: a fixed 3× pixel ratio, the iPhone's. A 2× device decodes a
// little more than it needs; read the view's ratio if that ever matters.
const double _pixelRatio = 3;

/// Photos are 4:3. Fitting the long edge inside a square leaves the short edge
/// at 3/4 of it, and `BoxFit.cover` needs the short edge to fill the box, so
/// the square is widened by 4/3 to keep a cropped photo sharp either way up.
const double _aspectAllowance = 4 / 3;

/// A stored photo decoded at the size a list actually draws it.
///
/// Stored photos are up to 2048px on the long edge. Decoding that for a 54pt
/// row costs memory and scroll smoothness for pixels nobody sees, so every
/// list goes through this instead of a bare [FileImage]. No thumbnail files
/// are written: the resize happens at decode, and the image cache keys on the
/// size, so equal boxes share one decode.
ImageProvider photoThumbnail(File file, {required double edge}) {
  final pixels = (edge * _pixelRatio * _aspectAllowance).ceil();
  return ResizeImage(
    FileImage(file),
    width: pixels,
    height: pixels,
    policy: ResizeImagePolicy.fit,
  );
}

/// The full-resolution photo behind a thumbnail, for the fullscreen viewer.
ImageProvider fullResolution(ImageProvider photo) =>
    photo is ResizeImage ? photo.imageProvider : photo;
