import 'package:flutter/widgets.dart';

/// Apple's minimum comfortable touch target.
const _minHitBox = 44.0;

/// Grows a small piece of text to a 44pt touch target without changing where
/// it sits, so `SKIP` and friends stay tappable at their design size.
class TapTarget extends StatelessWidget {
  const TapTarget({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHitBox),
        // `widthFactor` alongside `heightFactor`: without it the Center
        // expands to the full width of whatever slot it is given and centres
        // the child inside, so a left-aligned column's targets were not
        // actually left-aligned.
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}
