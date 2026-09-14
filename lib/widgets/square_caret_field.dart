import 'package:flutter/material.dart' show InputDecoration, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// One on-off cycle of the caret. Hard-stepped: half on, half off, no fade.
const _blinkPeriod = Duration(milliseconds: 1060);

const _caretWidth = 2.0;
const _caretHeight = 20.0;

/// A text field whose caret is a square lime bar drawn by the app.
///
/// The platform cursor is rounded on iOS and fades rather than steps, and
/// neither is SPEC's caret. The field keeps the real text input and hides its
/// own cursor; the bar is painted at the end of the text on top of it.
class SquareCaretField extends StatefulWidget {
  const SquareCaretField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.hint,
    required this.hintStyle,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.search,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final String hint;
  final TextStyle hintStyle;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;

  @override
  State<SquareCaretField> createState() => _SquareCaretFieldState();
}

class _SquareCaretFieldState extends State<SquareCaretField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: _blinkPeriod,
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_sync);
    widget.controller.addListener(_onText);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBlink();
  }

  @override
  void didUpdateWidget(SquareCaretField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_sync);
      widget.focusNode.addListener(_sync);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  bool get _isMotionReduced => MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (!mounted) return;
    _syncBlink();
    setState(() {});
  }

  /// Blinks only while focused, and holds solid under Reduce Motion.
  void _syncBlink() {
    final shouldBlink = widget.focusNode.hasFocus && !_isMotionReduced;
    if (shouldBlink && !_blink.isAnimating) {
      _blink.repeat();
    } else if (!shouldBlink) {
      _blink
        ..stop()
        ..value = 0;
    }
  }

  /// A keystroke restarts the cycle on its "on" half, so the caret never
  /// vanishes while the user is typing.
  void _onText() {
    if (_blink.isAnimating) {
      _blink
        ..value = 0
        ..repeat();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_sync);
    widget.controller.removeListener(_onText);
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = _measure(context);
        final left = textWidth.clamp(0.0, constraints.maxWidth - _caretWidth);

        return Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: widget.style,
              showCursor: false,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: widget.hintStyle,
              ),
            ),
            if (widget.focusNode.hasFocus)
              Positioned(
                left: left,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _blink,
                    builder: (context, _) => Opacity(
                      // Hard step: on for the first half, off for the second.
                      opacity: _blink.value < 0.5 ? 1 : 0,
                      child: const SizedBox(
                        key: ValueKey('square-caret'),
                        width: _caretWidth,
                        height: _caretHeight,
                        child: ColoredBox(color: SpecColors.accent),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _measure(BuildContext context) {
    final text = widget.controller.text;
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
