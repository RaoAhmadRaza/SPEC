import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';

/// Everything the add flow collected, handed over by SAVE.
@immutable
class SpecDraft {
  const SpecDraft({
    required this.type,
    required this.kind,
    required this.value,
    required this.zone,
    this.fieldName,
    this.photo,
    this.remindEveryMonths,
    this.name,
    this.notes,
  });

  final AddType type;
  final SpecKind kind;
  final String value;
  final String zone;

  /// What the user called the field when [kind] is OTHER.
  final String? fieldName;
  final File? photo;
  final int? remindEveryMonths;

  /// The object's name when the flow already knows it — a library pick's
  /// `Tyre`, or what was typed on screen 08. Null falls back to type and kind.
  final String? name;

  /// An optional line of free text, stored through [cleanNotes].
  final String? notes;
}

final _hexPaint = RegExp(r'^#?([0-9a-fA-F]{6})$');

/// The row SAVE writes. The zone and photo travel separately, because the
/// repository resolves both inside its own transaction.
ObjectsCompanion objectDraftFrom(SpecDraft draft, {DateTime? at}) {
  final now = at ?? DateTime.now();
  return ObjectsCompanion.insert(
    name: _nameOf(draft),
    type: draft.type.name,
    specKind: draft.kind.name,
    specValue: _valueOf(draft),
    remindEveryMonths: Value(draft.remindEveryMonths),
    createdAt: now,
    updatedAt: now,
    notes: Value(cleanNotes(draft.notes)),
  );
}

/// `Device filter`. Step 05 never asks for a name, so unless the flow brought
/// one in, the type and kind stand in until the user renames it on screen 03.
String _nameOf(SpecDraft draft) {
  final given = draft.name?.trim() ?? '';
  if (given.isNotEmpty) return given;
  final type = addTypeLabels[draft.type]!;
  if (draft.kind != SpecKind.other) return '$type ${draft.kind.name}';
  final named = draft.fieldName?.trim() ?? '';
  return named.isEmpty ? type : named;
}

String _valueOf(SpecDraft draft) {
  final value = draft.value.trim();
  if (draft.kind != SpecKind.paint) return value;
  final hex = _hexPaint.firstMatch(value)?.group(1);
  return hex == null ? value : '#${hex.toUpperCase()}';
}
