import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Half of the caret's 1060ms hard-step cycle.
const _blinkHalfPeriod = Duration(milliseconds: 530);

const _caretWidth = 2.0;
const _caretHeight = 24.0;

const _underlineHeight = 1.5;
const _underlineGap = 6.0;
const _underlineFade = Duration(milliseconds: 200);

/// One line of editable text with SPEC's square lime caret and a 1.5pt
/// underline that fades in when the field appears.
///
/// [EditableText]'s own cursor blinks on a fixed 500ms half period and fades
/// on iOS, so it is hidden and this draws the design's caret instead: square,
/// 2 × 24, on a hard 530ms step with no fade.
class SquareCaretField extends StatefulWidget {
  const SquareCaretField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.onSubmitted,
    this.placeholder,
    this.placeholderStyle,
    this.maxLength,
    this.underlineColor = const Color(0x4DFFFFFF),
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final ValueChanged<String> onSubmitted;
  final String? placeholder;
  final TextStyle? placeholderStyle;
  final int? maxLength;
  final Color underlineColor;

  @override
  State<SquareCaretField> createState() => _SquareCaretFieldState();
}

class _SquareCaretFieldState extends State<SquareCaretField> {
  Timer? _blink;
  bool _isCaretOn = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_restartBlink);
    widget.focusNode.addListener(_restartBlink);
    _restartBlink();
  }

  @override
  void didUpdateWidget(SquareCaretField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_restartBlink);
      widget.controller.addListener(_restartBlink);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_restartBlink);
      widget.focusNode.addListener(_restartBlink);
    }
  }

  @override
  void dispose() {
    _blink?.cancel();
    widget.controller.removeListener(_restartBlink);
    widget.focusNode.removeListener(_restartBlink);
    super.dispose();
  }

  /// Typing or refocusing shows the caret solid before it resumes blinking,
  /// the way every text field behaves.
  void _restartBlink() {
    _blink?.cancel();
    if (!mounted) return;
    setState(() => _isCaretOn = true);
    if (!widget.focusNode.hasFocus) return;
    _blink = Timer.periodic(_blinkHalfPeriod, (_) {
      if (mounted) setState(() => _isCaretOn = !_isCaretOn);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final isEmpty = text.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              if (isEmpty && widget.placeholder != null)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.placeholder!,
                      style: widget.placeholderStyle ?? widget.style,
                      maxLines: 1,
                    ),
                  ),
                ),
              EditableText(
                controller: widget.controller,
                focusNode: widget.focusNode,
                style: widget.style,
                cursorColor: const Color(0x00000000),
                backgroundCursorColor: const Color(0x00000000),
                showCursor: false,
                autocorrect: false,
                textCapitalization: TextCapitalization.words,
                keyboardAppearance: Brightness.dark,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  if (widget.maxLength case final int max)
                    LengthLimitingTextInputFormatter(max),
                ],
                onSubmitted: widget.onSubmitted,
              ),
              if (widget.focusNode.hasFocus && _isCaretOn)
                Positioned(
                  left: _caretX(context, constraints.maxWidth),
                  top: 0,
                  bottom: 0,
                  child: const Center(
                    child: SizedBox(
                      width: _caretWidth,
                      height: _caretHeight,
                      child: ColoredBox(color: SpecColors.accent),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: _underlineGap),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: _underlineFade,
          builder: (context, t, child) => Opacity(opacity: t, child: child),
          child: SizedBox(
            height: _underlineHeight,
            child: ColoredBox(color: widget.underlineColor),
          ),
        ),
      ],
    );
  }

  /// Where the selection's extent sits along the line.
  // ponytail: pins to the right edge once text overflows the field instead of
  // following EditableText's horizontal scroll; names are capped short enough
  // that this is rare.
  double _caretX(BuildContext context, double maxWidth) {
    final text = widget.controller.text;
    final offset = widget.controller.selection.extentOffset.clamp(
      0,
      text.length,
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final x = painter
        .getOffsetForCaret(TextPosition(offset: offset), Rect.zero)
        .dx;
    painter.dispose();
    return x.clamp(0, maxWidth - _caretWidth);
  }
}
