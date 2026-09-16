/// Hero tags shared by every screen that can open screen 03.
///
/// A leaf file with no imports, so Home and Search can name the flight's
/// source without depending on the screen it flies to.
String objectPhotoTag(int id) => 'obj-$id-photo';
String objectSpecTag(int id) => 'obj-$id-spec';
String objectZoneTag(int id) => 'obj-$id-zone';
