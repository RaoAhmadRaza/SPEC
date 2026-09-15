import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/add_kinds.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/theme/spec_tokens.dart';

const _caretSize = Size(2, 38);
const _caretFloor = 20.0;
const _blinkPeriod = Duration(milliseconds: 1060);

/// Long values shrink rather than wrap, down to this, then scroll.
const _fontFloor = 24.0;

/// `-0.045em`, kept proportional as the value shrinks.
const _trackingEm = -0.045;

/// The gap between the text's trailing edge and the caret. It is also the
/// slack [EditableText] needs past the glyphs before it starts scrolling them.
const _caretGap = 4.0;

const _ruleWeight = 1.5;
const _ruleGap = 12.0;

/// The value being typed at 42pt, with the caret drawn by the app.
///
/// The platform cursor is off: the design's caret is a square 2 × 38 bar that
/// blinks with a hard step, and sits after the text rather than inside it.
class AddValueField extends StatefulWidget {
  const AddValueField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.kind,
    this.isMotionReduced = false,
    this.textOpacity = 1,
    this.textShift = 0,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Picks the keyboard. Swapping it keeps the same focused field, so the
  /// keyboard changes layout without dropping and re-rising.
  final SpecKind kind;
  final bool isMotionReduced;

  /// The chip-switch wipe moves only the text; the rule and caret stay put.
  final double textOpacity;
  final double textShift;

  @override
  State<AddValueField> createState() => _AddValueFieldState();
}

class _AddValueFieldState extends State<AddValueField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: _blinkPeriod,
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
    _syncBlink();
  }

  @override
  void didUpdateWidget(AddValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    _syncBlink();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    _blink.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(_syncBlink);

  /// Blinks only while focused and motion is allowed; reduced motion holds it
  /// solid.
  void _syncBlink() {
    final shouldBlink = widget.focusNode.hasFocus && !widget.isMotionReduced;
    if (shouldBlink && !_blink.isAnimating) {
      _blink.repeat();
    } else if (!shouldBlink && _blink.isAnimating) {
      _blink
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // A near-empty field is only a few points wide; the whole row focuses.
      onTap: widget.focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(bottom: _ruleGap),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AddColors.fieldRule, width: _ruleWeight),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => _buildRow(context, constraints.maxWidth),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final available = math.max(0.0, width - _caretGap - _caretSize.width);
    final fontSize = _fittedSize(widget.controller.text, available, scaler);
    final style = AddText.value.copyWith(
      fontSize: fontSize,
      letterSpacing: fontSize * _trackingEm,
    );
    final textWidth = _measure(widget.controller.text, style, scaler);
    final caretHeight = math.max(
      _caretFloor,
      _caretSize.height * fontSize / AddText.value.fontSize!,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: math.min(textWidth + _caretGap, available + _caretGap),
          child: Opacity(
            opacity: widget.textOpacity,
            child: Transform.translate(
              offset: Offset(0, widget.textShift),
              child: _buildField(style),
            ),
          ),
        ),
        _buildCaret(caretHeight),
      ],
    );
  }

  Widget _buildField(TextStyle style) {
    return EditableText(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: style,
      cursorColor: SpecColors.accent,
      backgroundCursorColor: SpecColors.ink45,
      showCursor: false,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      keyboardType: keyboardFor(widget.kind),
      textCapitalization: capitalizationFor(widget.kind),
      keyboardAppearance: Brightness.dark,
      textInputAction: TextInputAction.done,
      maxLines: 1,
    );
  }

  Widget _buildCaret(double height) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (context, child) {
        final isLit =
            widget.focusNode.hasFocus &&
            (widget.isMotionReduced || _blink.value < 0.5);
        return Opacity(opacity: isLit ? 1 : 0, child: child);
      },
      child: SizedBox(
        width: _caretSize.width,
        height: height,
        child: const ColoredBox(color: SpecColors.accent),
      ),
    );
  }

  /// 42pt until the text no longer fits, then scaled to fit, never below the
  /// floor. Past the floor the field scrolls, like any single-line field.
  double _fittedSize(String text, double available, TextScaler scaler) {
    const full = 42.0;
    if (text.isEmpty || available <= 0) return full;
    final natural = _measure(
      text,
      AddText.value.copyWith(fontSize: full),
      scaler,
    );
    if (natural <= available) return full;
    return math.max(_fontFloor, full * available / natural);
  }

  double _measure(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// A single mono line with its placeholder drawn behind it: OTHER's field
/// name and a new zone's name. Plain [EditableText], so the add sheet needs no
/// Material ancestor.
class AddMonoInput extends StatelessWidget {
  const AddMonoInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.focusNode,
    this.textCapitalization = TextCapitalization.characters,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final FocusNode focusNode;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? Text(placeholder, maxLines: 1, style: AddText.monoLabel)
              : const SizedBox.shrink(),
        ),
        EditableText(
          controller: controller,
          focusNode: focusNode,
          style: AddText.fieldName,
          cursorColor: SpecColors.accent,
          backgroundCursorColor: SpecColors.ink45,
          cursorWidth: 2,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: textCapitalization,
          keyboardAppearance: Brightness.dark,
          textInputAction: textInputAction,
          maxLines: 1,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
