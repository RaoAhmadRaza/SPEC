import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

/// Keeps Material's typography out of a [TextField].
///
/// A text field merges its style onto the theme's `bodyLarge` (`titleMedium`
/// before Material 3), and that carries a 1.5 line height. Every SPEC style
/// leaves height unset so the font's own metrics apply, the way CSS `normal`
/// does — so the merge would make each field taller than the design.
class PlainFieldTheme extends StatelessWidget {
  const PlainFieldTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          bodyLarge: const TextStyle(),
          titleMedium: const TextStyle(),
        ),
      ),
      child: child,
    );
  }
}

/// A hero's flight is drawn in the overlay, outside the page's
/// [DefaultTextStyle]. Carrying the destination's in keeps every glyph at the
/// size it has at both ends, so a hero that flies onto itself cannot jump.
Widget keepTextStyleShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return DefaultTextStyle(
    style: DefaultTextStyle.of(toHeroContext).style,
    child: (toHeroContext.widget as Hero).child,
  );
}
