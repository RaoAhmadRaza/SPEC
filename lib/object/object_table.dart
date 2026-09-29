import 'package:flutter/widgets.dart';

import 'package:spec/data/models/spec_models.dart';
import 'package:spec/object/object_inline_edit.dart';
import 'package:spec/object/object_tokens.dart';

/// Three to a row, always — a short object leaves the trailing cells empty
/// rather than spreading two values across the width.
const kTableColumns = 3;

const _cellGap = 8.0;
const _cellPad = 16.0;
const _ruleWeight = 1.0;

/// One cell Edit opens up for a field that does not exist yet: a label and
/// a value, both typed.
class NewSpecCell {
  final label = TextEditingController();
  final value = TextEditingController();
  final labelFocus = FocusNode();
  final valueFocus = FocusNode();

  /// Blank cells add nothing on SAVE.
  bool get isBlank => label.text.trim().isEmpty && value.text.trim().isEmpty;

  void dispose() {
    label.dispose();
    value.dispose();
    labelFocus.dispose();
    valueFocus.dispose();
  }
}

/// The three-column attribute block, ruled top and bottom.
///
/// The rules are widgets rather than a `Border` because they grow from the
/// left on entrance, which a decoration cannot do.
class SpecTable extends StatelessWidget {
  const SpecTable({
    super.key,
    required this.fields,
    required this.controllers,
    required this.focusNodes,
    required this.isEditing,
    required this.editRule,
    required this.ruleGrow,
    required this.wrapCell,
    this.newCells = const [],
  });

  final List<SpecAttribute> fields;

  /// The empty cells Edit fills out after [fields], so a field can be added.
  /// Drawn only while editing.
  final List<NewSpecCell> newCells;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isEditing;

  /// Fades the per-value rules in when `Edit` opens.
  final Animation<double> editRule;

  /// Scales the top and bottom rules out from the left on entrance.
  final Animation<double> ruleGrow;

  final Widget Function(int index, Widget child) wrapCell;

  int get _cellCount => fields.length + (isEditing ? newCells.length : 0);

  int get _rowCount =>
      _cellCount == 0 ? 1 : (_cellCount + kTableColumns - 1) ~/ kTableColumns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Rule(ruleGrow),
        // More than three fields stacks a second row, which carries no rule of
        // its own: the block stays one ruled band, not two tables.
        for (var row = 0; row < _rowCount; row++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var column = 0; column < kTableColumns; column++)
                  Expanded(child: _cell(row * kTableColumns + column, column)),
              ],
            ),
          ),
        _Rule(ruleGrow),
      ],
    );
  }

  Widget _cell(int index, int column) {
    // The last column has no divider to its right: the page edge is the rule.
    final isLast = column == kTableColumns - 1;

    return wrapCell(
      index,
      Container(
        padding: EdgeInsets.fromLTRB(
          column == 0 ? 0 : _cellPad,
          _cellPad,
          0,
          _cellPad,
        ),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: ObjectColors.ruleInner,
                    width: _ruleWeight,
                  ),
                ),
              ),
        child: switch (index - fields.length) {
          < 0 => _CellContent(
            label: fields[index].label,
            controller: controllers[index],
            focusNode: focusNodes[index],
            isEditing: isEditing,
            editRule: editRule,
          ),
          final slot when isEditing && slot < newCells.length =>
            _NewCellContent(
              index: slot,
              cell: newCells[slot],
              editRule: editRule,
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _CellContent extends StatelessWidget {
  const _CellContent({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.editRule,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final Animation<double> editRule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: ObjectText.tableLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: _cellGap),
        InlineValue(
          controller: controller,
          focusNode: focusNode,
          style: ObjectText.tableValue,
          isEditing: isEditing,
          rule: editRule,
        ),
      ],
    );
  }
}

/// An empty cell while editing: the label typed where a label sits, the
/// value where a value sits, each hinted until something is in it.
class _NewCellContent extends StatelessWidget {
  const _NewCellContent({
    required this.index,
    required this.cell,
    required this.editRule,
  });

  final int index;
  final NewSpecCell cell;
  final Animation<double> editRule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InlineValue(
          key: ValueKey('new-field-label-$index'),
          controller: cell.label,
          focusNode: cell.labelFocus,
          style: ObjectText.tableLabel,
          isEditing: true,
          rule: editRule,
          hint: 'LABEL',
        ),
        const SizedBox(height: _cellGap),
        InlineValue(
          key: ValueKey('new-field-value-$index'),
          controller: cell.value,
          focusNode: cell.valueFocus,
          style: ObjectText.tableValue,
          isEditing: true,
          rule: editRule,
          hint: 'Add',
        ),
      ],
    );
  }
}

/// One of the block's two outer rules, grown from the left.
///
/// Scaled on X alone: a 1pt band scaled on both axes would vanish.
class _Rule extends StatelessWidget {
  const _Rule(this.grow);

  final Animation<double> grow;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: grow,
      builder: (context, child) => Transform.scale(
        scaleX: grow.value,
        scaleY: 1,
        alignment: Alignment.centerLeft,
        child: child,
      ),
      child: const SizedBox(
        height: _ruleWeight,
        child: ColoredBox(color: ObjectColors.ruleStrong),
      ),
    );
  }
}
