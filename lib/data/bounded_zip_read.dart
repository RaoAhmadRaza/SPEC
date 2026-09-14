import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Compressed input is fed to the inflater this much at a time, so at most one
/// chunk's worth of output sits in memory before the cap is checked again.
const _chunkBytes = 64 * 1024;

/// Why a bounded read refused an entry.
enum BoundedReadFailure {
  /// More than the cap came out, or would have.
  tooLarge,

  /// The entry uses a compression SPEC never writes and will not decode.
  unsupported,

  /// The compressed data ended early or is not valid deflate.
  damaged,
}

class BoundedReadException implements Exception {
  const BoundedReadException(this.failure);

  final BoundedReadFailure failure;

  @override
  String toString() => 'BoundedReadException: ${failure.name}';
}

/// Reads [entry]'s bytes without ever holding more than [max] of them.
///
/// `ArchiveFile.readBytes` inflates an entry to completion before anyone can
/// look at its length, and the size a zip header declares is written by
/// whoever made the zip. A few megabytes of deflate can expand a thousandfold,
/// so a backup built to hurt could exhaust the phone's memory before any
/// size check ran. This inflates chunk by chunk and stops the moment the
/// output passes [max], whatever the header claims.
Uint8List readZipEntryBounded(ArchiveFile entry, int max) {
  final raw = entry.rawContent;
  if (raw == null) return Uint8List(0);

  final compression = entry.compression ?? CompressionType.none;
  if (compression == CompressionType.bzip2) {
    throw const BoundedReadException(BoundedReadFailure.unsupported);
  }

  final stream = raw.getStream(decompress: false);
  final start = stream.position;
  try {
    // Deflate never meaningfully grows data, so compressed input larger than
    // the cap cannot be a legitimate entry under it — and a stored entry's
    // compressed length is its length.
    if (stream.length > max) {
      throw const BoundedReadException(BoundedReadFailure.tooLarge);
    }
    return switch (compression) {
      CompressionType.none => stream.toUint8List(),
      CompressionType.deflate => _inflateBounded(stream, max),
      CompressionType.bzip2 => throw const BoundedReadException(
        BoundedReadFailure.unsupported,
      ),
    };
  } finally {
    // The zip reader reuses this stream; leave it where it was found.
    stream.setPosition(start);
  }
}

Uint8List _inflateBounded(InputStream compressed, int max) {
  final filter = RawZLibFilter.inflateFilter(raw: true);
  final output = BytesBuilder(copy: false);

  void drain({required bool end}) {
    while (true) {
      final List<int>? chunk;
      try {
        chunk = filter.processed(flush: !end, end: end);
      } on FormatException {
        throw const BoundedReadException(BoundedReadFailure.damaged);
      }
      if (chunk == null) return;
      if (output.length + chunk.length > max) {
        throw const BoundedReadException(BoundedReadFailure.tooLarge);
      }
      output.add(chunk);
    }
  }

  while (!compressed.isEOS) {
    final remaining = compressed.length;
    final take = remaining < _chunkBytes ? remaining : _chunkBytes;
    final bytes = compressed.readBytes(take).toUint8List();
    try {
      filter.process(bytes, 0, bytes.length);
    } on FormatException {
      throw const BoundedReadException(BoundedReadFailure.damaged);
    }
    drain(end: false);
  }
  drain(end: true);
  return output.takeBytes();
}
