import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/home/home_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _gapNoteToTitle = 28.0;
const _gapTitleToBody = 10.0;
const _gapBodyToButton = 24.0;
const _gapButtonToSteps = 30.0;

const _buttonHeight = 46.0;
const _buttonGap = 12.0;

const _noteRuleWidth = 20.0;

const _steps = [
  ('01', 'PHOTOGRAPH THE THING'),
  ('02', 'KEEP THE ONE NUMBER'),
  ('03', 'FIND IT IN THE AISLE'),
];

const _leftNote = ['CAPTURE', 'LABEL', 'ORGANIZE', 'FIND'];

/// What fills Home when there is nothing saved.
///
/// Deliberately not a card. A card would promise a list that does not exist
/// yet; this is a picture of what the app is for.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key, required this.onAdd, required this.wrap});

  final VoidCallback onAdd;

  /// Lets the screen stagger the four blocks without this widget knowing
  /// anything about the entrance timeline.
  final Widget Function(int index, Widget child) wrap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        wrap(
          0,
          const Align(
            alignment: Alignment.centerLeft,
            child: _SideNote(lines: _leftNote),
          ),
        ),
        const SizedBox(height: _gapNoteToTitle),
        wrap(
          1,
          const Column(
            children: [
              Text('Add Something', style: HomeText.emptyTitle),
              SizedBox(height: _gapTitleToBody),
              Text(
                'Save the details for future you.',
                style: HomeText.emptyBody,
              ),
            ],
          ),
        ),
        const SizedBox(height: _gapBodyToButton),
        wrap(2, Center(child: _FirstItemButton(onTap: onAdd))),
        const SizedBox(height: _gapButtonToSteps),
        wrap(3, const _StepsRow()),
      ],
    );
  }
}

/// The four words the app does, hanging off the left edge.
class _SideNote extends StatelessWidget {
  const _SideNote({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines) Text(line, style: HomeText.note),
        const SizedBox(height: 6),
        const SizedBox(
          width: _noteRuleWidth,
          height: 1,
          child: ColoredBox(color: HomeColors.noteRule),
        ),
      ],
    );
  }
}

/// The only action on the screen, so it is outlined in lime and lit.
class _FirstItemButton extends StatefulWidget {
  const _FirstItemButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FirstItemButton> createState() => _FirstItemButtonState();
}

class _FirstItemButtonState extends State<_FirstItemButton> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) => setState(() => _isPressed = isPressed);

  void _onTap() {
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          height: _buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: HomeColors.firstItemFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: SpecColors.accent, width: 1.2),
            boxShadow: const [
              BoxShadow(color: HomeColors.firstItemGlow, blurRadius: 16),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+',
                style: TextStyle(
                  fontFamily: SpecFonts.display,
                  fontSize: 18,
                  color: SpecColors.accent,
                ),
              ),
              SizedBox(width: _buttonGap),
              Text('ADD YOUR FIRST ITEM', style: HomeText.firstItem),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three steps, centred under the action.
class _StepsRow extends StatelessWidget {
  const _StepsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 1,
          height: 57,
          child: ColoredBox(color: HomeColors.noteRule),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (number, label) in _steps)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(number, style: HomeText.stepNumber),
                  const SizedBox(width: 14),
                  Text(label, style: HomeText.stepLabel),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
