import 'package:flutter/widgets.dart';

import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/manual_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _buttonHeight = 58.0;
const _buttonRadius = BorderRadius.all(Radius.circular(999));
const _shadowBlur = 34.0;
const _shadowOffset = Offset(0, 14);

/// Transparent lime, so the shadow fades rather than popping when enabled.
const _shadowOff = Color(0x00D7FF3E);

const _stateDuration = Duration(milliseconds: 200);
const _pressDownDuration = Duration(milliseconds: 100);
const _pressUpDuration = Duration(milliseconds: 140);
const _pressScale = 0.96;
const _instant = Duration.zero;

/// `ADD MANUALLY`. The only lime fill on screen, and grey while `NAME` is
/// empty — never red, never shaking.
class ManualAddButton extends StatefulWidget {
  const ManualAddButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
    this.isMotionReduced = false,
  });

  final bool isEnabled;
  final VoidCallback onPressed;
  final bool isMotionReduced;

  @override
  State<ManualAddButton> createState() => _ManualAddButtonState();
}

class _ManualAddButtonState extends State<ManualAddButton> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (!widget.isEnabled || _isPressed == isPressed) return;
    setState(() => _isPressed = isPressed);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.isEnabled;
    return Semantics(
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        onTapDown: (details) => _setPressed(true),
        onTapUp: (details) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed && !widget.isMotionReduced ? _pressScale : 1,
          duration: widget.isMotionReduced
              ? _instant
              : (_isPressed ? _pressDownDuration : _pressUpDuration),
          curve: _isPressed ? Curves.easeOut : Curves.easeOutBack,
          child: AnimatedContainer(
            duration: widget.isMotionReduced ? _instant : _stateDuration,
            curve: Curves.easeOut,
            height: _buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isEnabled
                  ? SpecColors.accent
                  : ManualColors.buttonDisabledFill,
              borderRadius: _buttonRadius,
              boxShadow: [
                BoxShadow(
                  color: isEnabled ? AddColors.continueShadow : _shadowOff,
                  blurRadius: _shadowBlur,
                  offset: _shadowOffset,
                ),
              ],
            ),
            child: AnimatedDefaultTextStyle(
              duration: widget.isMotionReduced ? _instant : _stateDuration,
              style: isEnabled
                  ? SpecText.nextButton
                  : ManualText.buttonDisabled,
              child: const Text('ADD MANUALLY'),
            ),
          ),
        ),
      ),
    );
  }
}
