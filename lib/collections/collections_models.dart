import 'package:flutter/widgets.dart';

/// One zone row as screen 06 draws it.
///
/// A presentation model rather than the database row, so the screen stays
/// buildable in a test with no database and no photo files.
@immutable
class CollectionZone {
  const CollectionZone({
    required this.id,
    required this.name,
    required this.count,
    this.specs = const [],
    this.photo,
  });

  final int id;
  final String name;
  final int count;

  /// The newest objects' specs, newest first.
  final List<String> specs;

  final ImageProvider? photo;

  /// `B22 · E27 · LT1000P`.
  String get specSample => specs.join(' · ');
}

/// What Settings and Collections both say once a backup has been shared.
const kBackupReady = 'BACKUP READY';

/// Why a new or renamed zone name was refused. The field caps length and a
/// blank name never commits, so a taken name is the only refusal a user can
/// reach.
const kZoneNameTaken = 'ALREADY A ZONE';

/// `04`, not `4`; three digits run unpadded.
String formatZoneCount(int count) => count.toString().padLeft(2, '0');

/// `41 OBJECTS`, and `1 OBJECT`.
String countLabel(int count, String noun) =>
    '$count ${count == 1 ? noun : '${noun}S'}';

/// Index of the one strictly largest zone, or null on a tie or when every
/// zone is empty — lime marks the biggest zone, never a selection.
int? largestZoneIndex(List<CollectionZone> zones) {
  int? best;
  var most = 0;
  var isTied = false;
  for (var i = 0; i < zones.length; i++) {
    final count = zones[i].count;
    if (count > most) {
      most = count;
      best = i;
      isTied = false;
    } else if (count == most && count > 0) {
      isTied = true;
    }
  }
  return isTied ? null : best;
}

/// The cut corner rotates down the list: bottom-left, bottom-right, top-right,
/// top-left, then repeats.
BorderRadius zoneThumbRadius(int index) =>
    _thumbCuts[index % _thumbCuts.length];

const _big = Radius.circular(18);
const _cut = Radius.circular(5);

const _thumbCuts = [
  BorderRadius.only(
    topLeft: _big,
    topRight: _big,
    bottomRight: _big,
    bottomLeft: _cut,
  ),
  BorderRadius.only(
    topLeft: _big,
    topRight: _big,
    bottomRight: _cut,
    bottomLeft: _big,
  ),
  BorderRadius.only(
    topLeft: _big,
    topRight: _cut,
    bottomRight: _big,
    bottomLeft: _big,
  ),
  BorderRadius.only(
    topLeft: _cut,
    topRight: _big,
    bottomRight: _big,
    bottomLeft: _big,
  ),
];
