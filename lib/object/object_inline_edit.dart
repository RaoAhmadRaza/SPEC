import 'package:flutter/widgets.dart';

import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// How far under a value its edit rule sits.
const _ruleDrop = 5.0;
const _ruleWeight = 1.5;

/// EditableText's default 20, plus the floating bar and its margin: the
/// scroll view runs under the bar, so revealing a focused field has to clear
/// it as well as the keyboard.
final _scrollPadding = EdgeInsets.fromLTRB(
  20,
  20,
  20,
  20 + ObjectMetrics.page.bottom + ObjectMetrics.barHeight,
);

/// A value that becomes editable in place — no new route, no modal.
///
/// The rule is drawn outside the layout rather than added to it, so opening
/// `Edit` never moves anything on the page.
class InlineValue extends StatelessWidget {
  const InlineValue({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.isEditing,
    required this.rule,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.resting,
    this.hint,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final bool isEditing;

  /// 0 → 1 as the rules fade in.
  final Animation<double> rule;

  final TextAlign textAlign;
  final int maxLines;

  /// The resting presentation, when plain text is not enough — the spec, which
  /// shrinks to fit.
  final Widget? resting;

  /// Shown dim while editing an empty value, so a field with nothing in it
  /// yet still reads as a field.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final editor = isEditing
        ? EditableText(
            controller: controller,
            focusNode: focusNode,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            cursorColor: SpecColors.accent,
            backgroundCursorColor: SpecColors.ink45,
            selectionColor: SpecColors.ink45,
            cursorWidth: 2,
            scrollPadding: _scrollPadding,
          )
        : null;
    final hint = this.hint;
    final child = editor == null
        ? resting ??
              Text(
                controller.text,
                style: style,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              )
        : hint == null
        ? editor
        : Stack(
            children: [
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? Text(
                        hint,
                        style: style.copyWith(color: SpecColors.ink45),
                        textAlign: textAlign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
              editor,
            ],
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: -_ruleDrop,
          child: FadeTransition(
            opacity: rule,
            child: const SizedBox(
              height: _ruleWeight,
              child: ColoredBox(color: ObjectColors.editRule),
            ),
          ),
        ),
      ],
    );
  }
}
