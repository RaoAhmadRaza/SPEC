import 'package:flutter/widgets.dart';

import 'package:spec/add/plain_field_theme.dart';
import 'package:spec/home/home_icons.dart';
import 'package:spec/search/search_pill.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';
import 'package:spec/widgets/square_caret_field.dart';

/// 07 and 08 draw the same pill, so a push between them flies it onto itself:
/// it holds its place and its lime border, and only its contents change.
const kLibrarySearchTag = 'library-search';

/// CSS `blur(30px)` is a 15pt sigma.
const _pillBlur = 15.0;
const _glyphSize = 19.0;
const _gap = 12.0;

/// The add flow's search pill, on Search's shell so 07 and 08 match exactly.
class LibrarySearchPill extends StatelessWidget {
  const LibrarySearchPill({
    super.key,
    required this.controller,
    required this.focusNode,
    this.placeholder = 'What is it called?',
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: kLibrarySearchTag,
      flightShuttleBuilder: _shuttle,
      child: SearchPillShell(
        borderColor: SearchColors.pillBorderFocused,
        blur: _pillBlur,
        flightChild: _row(_inertQuery()),
        child: GestureDetector(
          // The whole pill focuses the field, not only the query's glyphs.
          onTap: focusNode.requestFocus,
          behavior: HitTestBehavior.opaque,
          child: _row(
            PlainFieldTheme(
              child: SquareCaretField(
                controller: controller,
                focusNode: focusNode,
                style: SearchText.query.copyWith(fontSize: 16),
                hint: placeholder,
                hintStyle: _hintStyle,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(Widget field) => Row(
    children: [
      const HomeIcon.search(size: _glyphSize, color: SpecColors.ink85),
      const SizedBox(width: _gap),
      Expanded(child: field),
    ],
  );

  Widget _inertQuery() {
    final query = controller.text;
    return Text(
      query.isEmpty ? placeholder : query,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: query.isEmpty
          ? _hintStyle
          : SearchText.query.copyWith(fontSize: 16),
    );
  }
}

const _hintStyle = TextStyle(
  fontFamily: SpecFonts.display,
  fontSize: 16,
  color: SpecColors.ink60,
);

/// A focused field copied into the flight overlay would fight the real one for
/// its focus node, so the flight draws the destination's inert twin.
Widget _shuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final shell = (toHeroContext.widget as Hero).child as SearchPillShell;
  return DefaultTextStyle(
    style: DefaultTextStyle.of(toHeroContext).style,
    child: SearchPillShell(
      borderColor: shell.borderColor,
      blur: shell.blur,
      child: shell.flightChild ?? shell.child,
    ),
  );
}
