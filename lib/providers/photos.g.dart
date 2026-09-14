// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photos.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens the store and deletes files no row refers to — the orphans a crash
/// between writing a photo and inserting its row, or a restore, leaves behind.
///
/// A failed sweep costs disk space, not photos, so it is reported and the
/// store is still returned: every photo writer awaits this provider first.

@ProviderFor(photoStore)
final photoStoreProvider = PhotoStoreProvider._();

/// Opens the store and deletes files no row refers to — the orphans a crash
/// between writing a photo and inserting its row, or a restore, leaves behind.
///
/// A failed sweep costs disk space, not photos, so it is reported and the
/// store is still returned: every photo writer awaits this provider first.

final class PhotoStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<PhotoStore>,
          PhotoStore,
          FutureOr<PhotoStore>
        >
    with $FutureModifier<PhotoStore>, $FutureProvider<PhotoStore> {
  /// Opens the store and deletes files no row refers to — the orphans a crash
  /// between writing a photo and inserting its row, or a restore, leaves behind.
  ///
  /// A failed sweep costs disk space, not photos, so it is reported and the
  /// store is still returned: every photo writer awaits this provider first.
  PhotoStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoStoreHash();

  @$internal
  @override
  $FutureProviderElement<PhotoStore> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PhotoStore> create(Ref ref) {
    return photoStore(ref);
  }
}

String _$photoStoreHash() => r'006a49413a0432b4ddb58f330a363466445235a5';

@ProviderFor(photoCapture)
final photoCaptureProvider = PhotoCaptureProvider._();

final class PhotoCaptureProvider
    extends $FunctionalProvider<PhotoCapture, PhotoCapture, PhotoCapture>
    with $Provider<PhotoCapture> {
  PhotoCaptureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoCaptureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoCaptureHash();

  @$internal
  @override
  $ProviderElement<PhotoCapture> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoCapture create(Ref ref) {
    return photoCapture(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoCapture value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoCapture>(value),
    );
  }
}

String _$photoCaptureHash() => r'1f4a3d83a93955b0dc6acc5d6c7d33a9e0ba1588';
