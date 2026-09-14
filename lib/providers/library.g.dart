// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The bundled library, read once and held for the life of the app.
///
/// It ships inside the binary, which is what makes screen 07 work in
/// airplane mode and what `OFFLINE` on that screen is a statement of.

@ProviderFor(libraryItems)
final libraryItemsProvider = LibraryItemsProvider._();

/// The bundled library, read once and held for the life of the app.
///
/// It ships inside the binary, which is what makes screen 07 work in
/// airplane mode and what `OFFLINE` on that screen is a statement of.

final class LibraryItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LibraryItem>>,
          List<LibraryItem>,
          FutureOr<List<LibraryItem>>
        >
    with
        $FutureModifier<List<LibraryItem>>,
        $FutureProvider<List<LibraryItem>> {
  /// The bundled library, read once and held for the life of the app.
  ///
  /// It ships inside the binary, which is what makes screen 07 work in
  /// airplane mode and what `OFFLINE` on that screen is a statement of.
  LibraryItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryItemsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryItemsHash();

  @$internal
  @override
  $FutureProviderElement<List<LibraryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LibraryItem>> create(Ref ref) {
    return libraryItems(ref);
  }
}

String _$libraryItemsHash() => r'239a0eb09e121498692e5eb37130f142187992f0';
