// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Everything screen 03 renders for one object, live: stamping REPLACED or
/// saving an edit rewrites the row, and the screen follows it with no manual
/// invalidation. Null once the object has been deleted.

@ProviderFor(objectView)
final objectViewProvider = ObjectViewFamily._();

/// Everything screen 03 renders for one object, live: stamping REPLACED or
/// saving an edit rewrites the row, and the screen follows it with no manual
/// invalidation. Null once the object has been deleted.

final class ObjectViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ObjectView?>,
          ObjectView?,
          Stream<ObjectView?>
        >
    with $FutureModifier<ObjectView?>, $StreamProvider<ObjectView?> {
  /// Everything screen 03 renders for one object, live: stamping REPLACED or
  /// saving an edit rewrites the row, and the screen follows it with no manual
  /// invalidation. Null once the object has been deleted.
  ObjectViewProvider._({
    required ObjectViewFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'objectViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$objectViewHash();

  @override
  String toString() {
    return r'objectViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ObjectView?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ObjectView?> create(Ref ref) {
    final argument = this.argument as int;
    return objectView(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ObjectViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$objectViewHash() => r'213a441dd4bb31274e056596a8eca979993578c3';

/// Everything screen 03 renders for one object, live: stamping REPLACED or
/// saving an edit rewrites the row, and the screen follows it with no manual
/// invalidation. Null once the object has been deleted.

final class ObjectViewFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ObjectView?>, int> {
  ObjectViewFamily._()
    : super(
        retry: null,
        name: r'objectViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everything screen 03 renders for one object, live: stamping REPLACED or
  /// saving an edit rewrites the row, and the screen follows it with no manual
  /// invalidation. Null once the object has been deleted.

  ObjectViewProvider call(int id) =>
      ObjectViewProvider._(argument: id, from: this);

  @override
  String toString() => r'objectViewProvider';
}
