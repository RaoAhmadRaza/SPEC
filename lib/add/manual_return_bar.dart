import 'package:flutter/widgets.dart';

import 'package:spec/add/manual_tokens.dart';
import 'package:spec/home/home_glass.dart';
import 'package:spec/library/library_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _barHeight = 56.0;
const _barRadius = BorderRadius.all(Radius.circular(999));

/// 07's bottom bar: `blur(30px) saturate(200%)`.
const _barBlur = 15.0;
const _barSaturation = 2.0;
const _barPadding = EdgeInsets.fromLTRB(22, 7, 8, 7);
const _highlightHeight = 1.5;
const _shadowBlur = 40.0;
const _shadowOffset = Offset(0, 16);

const _pillPadding = EdgeInsets.symmetric(horizontal: 20);

const _inDuration = Duration(milliseconds: 280);
const _outDuration = Duration(milliseconds: 200);
const _instant = Duration.zero;

/// How far below its resting place the bar starts, as a fraction of itself.
const _riseFraction = 0.5;

/// The way back to 07 once the query matches something again.
///
/// Always laid out, so appearing never shifts the button under it; hidden it
/// takes no touches.
class ManualReturnBar extends StatelessWidget {
  const ManualReturnBar({
    super.key,
    required this.matches,
    required this.onTap,
    this.isMotionReduced = false,
  });

  /// Zero hides the bar. The count on the pill is live.
  final int matches;
  final VoidCallback onTap;
  final bool isMotionReduced;

  bool get _isVisible => matches > 0;

  @override
  Widget build(BuildContext context) {
    final duration = isMotionReduced
        ? _instant
        : (_isVisible ? _inDuration : _outDuration);
    return IgnorePointer(
      ignoring: !_isVisible,
      child: ExcludeSemantics(
        excluding: !_isVisible,
        child: AnimatedSlide(
          offset: Offset(0, _isVisible ? 0 : _riseFraction),
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _isVisible ? 1 : 0,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(height: _barHeight, child: _buildGlass()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlass() {
    return GlassSurface(
      borderRadius: _barRadius,
      blur: _barBlur,
      saturation: _barSaturation,
      fill: LibraryColors.barFill,
      borderColor: LibraryColors.barBorder,
      topHighlight: LibraryColors.barHighlight,
      topHighlightHeight: _highlightHeight,
      shadows: const [
        BoxShadow(
          color: LibraryColors.barShadow,
          blurRadius: _shadowBlur,
          offset: _shadowOffset,
        ),
      ],
      padding: _barPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Found it in the library',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ManualText.barLabel,
              ),
            ),
          ),
          Container(
            padding: _pillPadding,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SpecColors.accent,
              borderRadius: _barRadius,
            ),
            child: Text('SHOW $matches', style: ManualText.barPill),
          ),
        ],
      ),
    );
  }
}
