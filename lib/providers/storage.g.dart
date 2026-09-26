// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bytes SPEC keeps on this device: the database file and every photo.
///
/// Watches the archive counts so it weighs again whenever an object or a
/// photo comes or goes, instead of showing the size the page opened with.

@ProviderFor(storageBytes)
final storageBytesProvider = StorageBytesProvider._();

/// Bytes SPEC keeps on this device: the database file and every photo.
///
/// Watches the archive counts so it weighs again whenever an object or a
/// photo comes or goes, instead of showing the size the page opened with.

final class StorageBytesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Bytes SPEC keeps on this device: the database file and every photo.
  ///
  /// Watches the archive counts so it weighs again whenever an object or a
  /// photo comes or goes, instead of showing the size the page opened with.
  StorageBytesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageBytesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageBytesHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return storageBytes(ref);
  }
}

String _$storageBytesHash() => r'41d9cf7de9ab238d7742c7704175c6ce959817d0';
