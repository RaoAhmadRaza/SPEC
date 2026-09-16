import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/collections/collections_models.dart';

List<CollectionZone> _zones(List<int> counts) => [
  for (var i = 0; i < counts.length; i++)
    CollectionZone(id: i, name: 'Z$i', count: counts[i]),
];

void main() {
  group('largestZoneIndex', () {
    test('marks the one strictly largest zone', () {
      expect(largestZoneIndex(_zones([18, 4, 9, 7, 3])), 0);
    });

    test('marks nothing on a tie for largest', () {
      expect(largestZoneIndex(_zones([9, 4, 9])), isNull);
    });

    test('a tie below the largest does not clear it', () {
      expect(largestZoneIndex(_zones([3, 3, 9])), 2);
    });

    test('marks nothing when every zone is empty', () {
      expect(largestZoneIndex(_zones([0, 0])), isNull);
    });
  });

  test('counts pad to two digits and run three unpadded', () {
    expect(formatZoneCount(4), '04');
    expect(formatZoneCount(18), '18');
    expect(formatZoneCount(120), '120');
  });

  test('count labels take the singular for one', () {
    expect(countLabel(1, 'OBJECT'), '1 OBJECT');
    expect(countLabel(41, 'OBJECT'), '41 OBJECTS');
  });

  test('the thumb cut rotates BL, BR, TR, TL and repeats', () {
    const cut = Radius.circular(5);
    expect(zoneThumbRadius(0).bottomLeft, cut);
    expect(zoneThumbRadius(1).bottomRight, cut);
    expect(zoneThumbRadius(2).topRight, cut);
    expect(zoneThumbRadius(3).topLeft, cut);
    expect(zoneThumbRadius(4), zoneThumbRadius(0));
  });
}
