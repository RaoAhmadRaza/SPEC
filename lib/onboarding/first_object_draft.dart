import 'package:spec/add/add_icons.dart';
import 'package:spec/data/models/spec_models.dart';

/// The name, type and kind step 05 opens with for a chip on screen 11.
typedef FirstObjectShape = ({String name, AddType type, SpecKind kind});

/// What each suggestion chip on screen 11 stands for. Each kind is one of its
/// type's own chips, so step 05 never opens with none lit.
const _suggestionShapes = <String, FirstObjectShape>{
  'BULB': (name: 'Bulb', type: AddType.product, kind: SpecKind.model),
  'TYRE': (name: 'Tyre', type: AddType.car, kind: SpecKind.tyre),
  'CARTRIDGE': (name: 'Cartridge', type: AddType.product, kind: SpecKind.model),
  'FILTER': (name: 'Filter', type: AddType.device, kind: SpecKind.filter),
};

/// Turns the chip the user picked into the shape of their first object.
///
/// The spec itself is typed on step 05, which this shape pre-fills. The name
/// is also saved as the object's `library_term`, so the very first object the
/// user owns already answers the synonym search the design shows: looking for
/// `bulb` finds a headlight.
FirstObjectShape firstObjectShape(String suggestion) =>
    _suggestionShapes[suggestion.toUpperCase()] ??
    (name: suggestion, type: AddType.other, kind: SpecKind.other);
