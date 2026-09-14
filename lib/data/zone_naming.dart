import 'package:spec/data/models/spec_models.dart';

/// The zone an object is filed under, uppercased.
///
/// An object with no zone falls back to its type, which is what stops the
/// rail and the browse list from growing an unnamed bucket.
String zoneOf(ObjectSummary object) =>
    (object.zoneName ?? object.type.name).toUpperCase();

/// The zone's name as the user wrote it — `Garage Shelf`, never `Garage shelf`.
///
/// Only the type fallback is cased here, since `clothing` was never typed by
/// anyone.
String zoneNameOf(ObjectSummary object) =>
    object.zoneName ?? _titleCase(object.type.name);

String _titleCase(String value) => value.isEmpty
    ? value
    : value[0].toUpperCase() + value.substring(1).toLowerCase();

/// `HOME · CEILING`, the mono line under a result's name.
String zoneLineOf(ObjectSummary object) => [
  zoneOf(object),
  if (object.subLocation case final String sub) sub.toUpperCase(),
].join(' · ');
