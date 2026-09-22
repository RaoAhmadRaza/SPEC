import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/object/object_parts.dart';
import 'package:spec/settings/settings_parts.dart';
import 'package:spec/settings/settings_tokens.dart';

import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Collections' page geometry, so the two data screens share a margin.
const _side = 18.0;
const _top = 56.0;
const _bottom = 44.0;
const _blockGap = 20.0;
const _titleGap = 12.0;
const _lineGap = 10.0;

/// Tight enough to read as one list of actions, with each chip's 44pt touch
/// target doing the spacing.
const _chipGap = 4.0;

/// Holds one line of status even while empty, so a result arriving does not
/// shove the footer down.
const _statusMinHeight = 22.0;

const _enterDuration = Duration(milliseconds: 560);
const _busyFade = Duration(milliseconds: 160);

/// Actions stay visible while one runs, but read as unavailable.
const _busyOpacity = 0.4;

const _privacyLines = [
  'NO ACCOUNT',
  'NO CLOUD',
  'STAYS ON THIS PHONE',
  'NO TRACKING',
];

/// Screen 5: what SPEC holds, where it lives, and the three ways to take it
/// out, bring it back, or wipe it.
///
/// Pure presentation driven by callbacks, so its tests build it directly with
/// no ProviderScope. The route owns every await.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.version,
    required this.counts,
    required this.status,
    required this.isBusy,
    required this.onBack,
    required this.onExport,
    required this.onRestore,
    required this.onDeleteEverything,
  });

  /// `SPEC 1.0.1 (2)`.
  final String version;

  /// `41 OBJECTS · 96 PHOTOS`.
  final String counts;

  /// The last action's result or failure; null shows nothing.
  final String? status;

  /// True while an action runs. Every action ignores taps until it clears,
  /// so a second restore can never start under the first.
  final bool isBusy;

  final VoidCallback onBack;
  final VoidCallback onExport;
  final VoidCallback onRestore;
  final VoidCallback onDeleteEverything;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );

  bool _isMotionReduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMotionReduced = MediaQuery.disableAnimationsOf(context);
    // Reduce Motion lands on the finished page: no fade, no lift.
    if (_isMotionReduced) {
      _enter.value = 1;
      return;
    }
    if (_enter.status == AnimationStatus.dismissed) _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  /// Fades a block in over its slice of the entrance, lifting it by [dy].
  Widget _rise(double begin, double end, Widget child, {double dy = 0}) {
    final curve = Interval(begin, end, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: _enter,
      child: child,
      builder: (context, inner) {
        final t = curve.transform(_enter.value);
        return Opacity(
          opacity: t,
          child: dy == 0
              ? inner
              : Transform.translate(
                  offset: Offset(0, dy * (1 - t)),
                  child: inner,
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: SpecFonts.display,
        color: SpecColors.ink,
        decoration: TextDecoration.none,
      ),
      child: ColoredBox(
        color: SpecColors.bg,
        // Scrolls only when it must: large text, or a long format error.
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              // The bottom inset is not here: `SliverFillRemaining` fills the
              // remaining *paint* extent, which `SliverPadding` reduces by its
              // leading padding only. A trailing padding here is counted in
              // the scroll extent but the child still paints to the viewport's
              // bottom edge, which put the version line under the home
              // indicator. It goes inside the sliver instead.
              padding: EdgeInsets.fromLTRB(
                _side,
                SpecLayout.topInset(context, design: _top),
                _side,
                0,
              ),
              // No LayoutBuilder in here: this sliver measures its child's
              // intrinsic height, and a LayoutBuilder cannot report one.
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: SpecLayout.bottomInset(context, design: _bottom),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: _contentWidth(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rise(0, 0.3, GlassCircle.back(onTap: widget.onBack)),
                          const SizedBox(height: _blockGap),
                          _rise(0.06, 0.5, _buildTitle(), dy: 20),
                          const SizedBox(height: _blockGap),
                          _rise(
                            0.2,
                            0.52,
                            const SettingsRule(
                              color: CollectionsColors.ruleStrong,
                            ),
                          ),
                          const SizedBox(height: _blockGap),
                          _rise(0.26, 0.64, _buildPrivacy(), dy: 12),
                          const SizedBox(height: _blockGap),
                          _rise(
                            0.34,
                            0.66,
                            const SettingsRule(
                              color: CollectionsColors.hairline,
                            ),
                          ),
                          const SizedBox(height: _blockGap),
                          _rise(0.4, 0.8, _buildActions(), dy: 12),
                          const SizedBox(height: _blockGap),
                          _buildStatus(),
                          const Spacer(),
                          const SizedBox(height: _blockGap),
                          _rise(
                            0.5,
                            1,
                            Text(widget.version, style: SettingsText.version),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The column's width, capped so a 54pt title and a privacy paragraph do
  /// not run the full width of an iPad.
  double _contentWidth(BuildContext context) => math.min(
    MediaQuery.sizeOf(context).width - _side * 2,
    SpecLayout.maxContentWidth,
  );

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SETTINGS', style: SettingsText.title, maxLines: 1),
        const SizedBox(height: _titleGap),
        Text(
          widget.counts,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SettingsText.counts,
        ),
      ],
    );
  }

  Widget _buildPrivacy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in _privacyLines)
          Text(line, style: SettingsText.privacy),
        const SizedBox(height: _lineGap),
        const Text(
          'Everything you save lives only in SPEC on this phone. A backup is '
          'a file you keep.',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: SettingsText.body,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return IgnorePointer(
      ignoring: widget.isBusy,
      child: AnimatedOpacity(
        opacity: widget.isBusy ? _busyOpacity : 1,
        duration: _isMotionReduced ? Duration.zero : _busyFade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsChip(
              label: 'EXPORT BACKUP',
              tone: SettingsChipTone.accent,
              onTap: widget.onExport,
            ),
            const SizedBox(height: _chipGap),
            SettingsChip(
              label: 'RESTORE FROM BACKUP',
              tone: SettingsChipTone.plain,
              onTap: widget.onRestore,
            ),
            const SizedBox(height: _chipGap),
            SettingsChip(
              label: 'DELETE EVERYTHING',
              tone: SettingsChipTone.destructive,
              onTap: widget.onDeleteEverything,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    final status = widget.status;
    return Semantics(
      // Read out when it changes: it is the only answer an action gives.
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _statusMinHeight),
        child: status == null
            ? const SizedBox(width: double.infinity)
            // Two lines, not one: this is a live region, so truncating it
            // loses the only answer an action gives.
            : Text(
                status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SettingsText.status,
              ),
      ),
    );
  }
}
