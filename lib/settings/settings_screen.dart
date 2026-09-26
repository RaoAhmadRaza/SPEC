import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/object/object_parts.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/settings/settings_icons.dart';
import 'package:spec/settings/settings_parts.dart';
import 'package:spec/settings/settings_tokens.dart';
import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Measured off the design at its 402 × 874 canvas.
const _side = 22.0;
const _top = 56.0;
const _bottom = 34.0;
const _titleTop = 19.0;
const _ruleAbove = 16.5;
const _ruleBelow = 11.0;
const _cardGap = 9.0;
const _actionsAbove = 10.0;
const _aboutAbove = 16.5;
const _aboutGap = 12.0;
const _statusGap = 12.0;

/// A pill's hit area reaches 3pt past its outline, above and below. Every gap
/// that meets a pill gives those 3pt back so the drawn spacing still matches.
const _pillSlop = 3.0;
const _pillGap = 9.5 - _pillSlop * 2;

const _enterDuration = Duration(milliseconds: 560);
const _busyFade = Duration(milliseconds: 160);

/// Actions stay visible while one runs, but read as unavailable.
const _busyOpacity = 0.4;

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
    required this.storage,
    required this.status,
    required this.isBusy,
    required this.onBack,
    required this.onExport,
    required this.onRestore,
    required this.onDeleteEverything,
  });

  /// `SPEC 1.0.2 (3)`.
  final String version;

  /// What the title line and the two count cards read.
  final ArchiveCounts counts;

  /// `2.1 MB`, or null while it is still being weighed.
  final String? storage;

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
        // Scrolls only when it must: a short phone, large text, or a long
        // format error.
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            _side,
            SpecLayout.topInset(context, design: _top),
            _side,
            SpecLayout.bottomInset(context, design: _bottom),
          ),
          child: Center(
            child: SizedBox(
              width: _contentWidth(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rise(
                    0,
                    0.3,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GlassCircle.back(onTap: widget.onBack),
                    ),
                  ),
                  const SizedBox(height: _titleTop),
                  _rise(0.06, 0.5, _buildTitle(), dy: 20),
                  const SizedBox(height: _ruleAbove),
                  _rise(0.2, 0.52, const _Rule()),
                  const SizedBox(height: _ruleBelow),
                  _rise(0.26, 0.7, _buildCards(), dy: 12),
                  const SizedBox(height: _actionsAbove),
                  _rise(0.34, 0.74, const _Rule()),
                  const SizedBox(height: _aboutGap - _pillSlop),
                  _rise(0.4, 0.8, _buildActions(), dy: 12),
                  _buildStatus(),
                  const SizedBox(height: _aboutAbove - _pillSlop),
                  _rise(0.46, 0.86, const _Rule()),
                  const SizedBox(height: _aboutGap),
                  _rise(0.5, 1, _buildAbout(), dy: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The column's width, capped so a 54pt title and full-width cards do not
  /// run the full width of an iPad.
  double _contentWidth(BuildContext context) => math.min(
    MediaQuery.sizeOf(context).width - _side * 2,
    SpecLayout.maxContentWidth,
  );

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // No gap: the design sets the counts tight under the title's
        // baseline, closer than the title's own line box allows.
        // Shrinks rather than clips on a narrow phone at a raised text
        // scale; scaleDown leaves it untouched everywhere it already fits.
        const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('SETTINGS', style: SettingsText.title, maxLines: 1),
        ),
        Text(
          widget.counts.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SettingsText.counts,
        ),
      ],
    );
  }

  /// Backup is the one card that does something: it exports, like the lime
  /// pill below it. The rest only report.
  Widget _buildCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _busyGate(
          SettingsCard(
            glyph: SettingsGlyph.cloud,
            label: 'BACKUP',
            value: 'OFF',
            valueStyle: SettingsText.rowState,
            detail: 'Keep your specs safe.\nA backup is a file you keep.',
            onTap: widget.onExport,
          ),
        ),
        const SizedBox(height: _cardGap),
        SettingsCard(
          glyph: SettingsGlyph.phone,
          label: 'ON THIS PHONE',
          value: '${widget.counts.objects}',
          detail: 'Objects saved in SPEC\non this device.',
        ),
        const SizedBox(height: _cardGap),
        SettingsCard(
          glyph: SettingsGlyph.photo,
          label: 'PHOTOS',
          value: '${widget.counts.photos}',
          detail: 'Reference photos for\nyour objects.',
        ),
        const SizedBox(height: _cardGap),
        SettingsCard(
          glyph: SettingsGlyph.storage,
          label: 'STORAGE',
          value: widget.storage,
          detail: 'Space used by SPEC\non this device.',
        ),
      ],
    );
  }

  Widget _buildActions() {
    return _busyGate(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsPill(
            glyph: SettingsGlyph.share,
            label: 'EXPORT BACKUP',
            tone: SettingsPillTone.accent,
            onTap: widget.onExport,
          ),
          const SizedBox(height: _pillGap),
          SettingsPill(
            glyph: SettingsGlyph.share,
            label: 'RESTORE FROM BACKUP',
            tone: SettingsPillTone.plain,
            onTap: widget.onRestore,
          ),
          const SizedBox(height: _pillGap),
          SettingsPill(
            glyph: SettingsGlyph.trash,
            label: 'DELETE EVERYTHING',
            tone: SettingsPillTone.destructive,
            onTap: widget.onDeleteEverything,
          ),
        ],
      ),
    );
  }

  /// Visible while an action runs, but unavailable and reading that way.
  Widget _busyGate(Widget child) {
    return IgnorePointer(
      ignoring: widget.isBusy,
      child: AnimatedOpacity(
        opacity: widget.isBusy ? _busyOpacity : 1,
        duration: _isMotionReduced ? Duration.zero : _busyFade,
        child: child,
      ),
    );
  }

  /// Takes no room until there is something to say, so the page matches the
  /// design until an action answers.
  Widget _buildStatus() {
    final status = widget.status;
    return Semantics(
      // Read out when it changes: it is the only answer an action gives.
      liveRegion: true,
      child: status == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: _statusGap),
              // Two lines, not one: this is a live region, so truncating it
              // loses the only answer an action gives.
              child: Text(
                status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SettingsText.status,
              ),
            ),
    );
  }

  Widget _buildAbout() {
    return SettingsCard(
      glyph: SettingsGlyph.info,
      label: 'ABOUT',
      detail: widget.version,
      detailStyle: SettingsText.rowVersion,
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const SettingsRule(color: CollectionsColors.ruleStrong);
}
