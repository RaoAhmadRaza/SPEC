import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/data/models/spec_models.dart';

/// The NOTES field's controller: refuses text past [kNotesMaxLength]
/// characters, typed or pasted.
///
/// The cap sits on the controller rather than on the field because
/// [InlineValue] builds its EditableText with no input formatters. Every edit
/// still passes through [LengthLimitingTextInputFormatter], so the field
/// behaves exactly as a formatter would make it; [cleanNotes] caps again on
/// save, so the column never depends on this alone.
class NotesController extends TextEditingController {
  static final _limit = LengthLimitingTextInputFormatter(kNotesMaxLength);

  @override
  set value(TextEditingValue newValue) {
    super.value = _limit.formatEditUpdate(value, newValue);
  }
}
