import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, TextInputAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/library_search_pill.dart';
import 'package:spec/add/manual_add_button.dart';
import 'package:spec/add/manual_field_row.dart';
import 'package:spec/add/manual_heroes.dart';
import 'package:spec/add/manual_return_bar.dart';
import 'package:spec/add/manual_tokens.dart';
import 'package:spec/add/photo_drop_card.dart';
import 'package:spec/add/plain_field_theme.dart';
import 'package:spec/search/search_header.dart';
import 'package:spec/theme/spec_tokens.dart';

/// The same header every add step draws, so a push flies it onto itself.
const kAddStepHeaderTag = 'add-step-header';

/// 128 at the bottom clears the pinned button block.
const _pagePadding = EdgeInsets.fromLTRB(18, 56, 18, 128);
const _blockGap = 16.0;
const _nudge = 2.0;
const _verdictGap = 10.0;
const _ruleToText = 18.0;
const _bodyMaxWidth = 300.0;
const _photoHeight = 210.0;
const _fieldGap = 9.0;
const _hintGap = 12.0;
const _bottomInsets = EdgeInsets.fromLTRB(16, 0, 16, 24);
const _bottomGap = 10.0;

/// How far above the button block a focused field comes to rest.
const _revealGap = 12.0;
const _revealDuration = Duration(milliseconds: 220);

const _enterDuration = Duration(milliseconds: 620);
const _reducedDuration = Duration(milliseconds: 200);

/// The entrance starts at 40% of the 380ms push; the keyboard at 520ms.
const _enterDelay = Duration(milliseconds: 152);
const _reducedEnterDelay = Duration(milliseconds: 80);
const _focusDelay = Duration(milliseconds: 520);

const _chipFade = Duration(milliseconds: 180);
const _hintIn = Duration(milliseconds: 200);
const _hintOut = Duration(milliseconds: 160);

/// Of step 05's 420ms push: everything but the heroes goes in the first 200,
/// the spec value in the first 140.
const _exitAll = 200 / 420;
const _exitSpec = 140 / 420;

/// What the user named, carried to step 05. The spec may be empty.
@immutable
class ManualDraft {
  const ManualDraft({required this.name, required this.spec, this.photo});

  final String name;
  final String spec;
  final File? photo;
}

int _noMatches(String query) => 0;

/// Screen 08, the add flow's fallback: photograph it and name it yourself.
///
/// Pure presentation driven by callbacks, so a test builds it directly.
class NotInLibraryScreen extends StatefulWidget {
  const NotInLibraryScreen({
    super.key,
    required this.query,
    required this.onAdd,
    this.stepLabel = 'STEP 1 / 3',
    this.countLibraryMatches = _noMatches,
    this.pickPhoto,
    this.onCancel,
    this.onReturnToLibrary,
  });

  /// Empty when the user arrived through `ADD YOUR OWN` rather than a miss.
  final String query;
  final ValueChanged<ManualDraft> onAdd;

  /// Still step 1: naming the object is part of picking it.
  final String stepLabel;

  /// The live library, so an edited query can find its way back to 07.
  final int Function(String query) countLibraryMatches;
  final Future<File?> Function()? pickPhoto;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onReturnToLibrary;

  @override
  State<NotInLibraryScreen> createState() => _NotInLibraryScreenState();
}

class _NotInLibraryScreenState extends State<NotInLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );
  late final Animation<double> _rule = _seg(0.00, 0.28);
  late final Animation<double> _headline = _seg(0.06, 0.50);
  late final Animation<double> _body = _seg(0.18, 0.56);
  late final Animation<double> _photoIn = _seg(0.30, 0.70);
  late final List<Animation<double>> _fields = [
    for (var i = 0; i < 2; i++) _seg(0.42 + i * 0.06, 0.42 + i * 0.06 + 0.34),
  ];
  late final Animation<double> _bottom = _seg(0.58, 1.00);

  late final TextEditingController _search = TextEditingController(
    text: widget.query,
  );
  late final TextEditingController _name = TextEditingController(
    text: sentenceCase(widget.query),
  );
  final TextEditingController _spec = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _specFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _nameRowKey = GlobalKey();
  final GlobalKey _specRowKey = GlobalKey();
  final GlobalKey _returnBarKey = GlobalKey();
  final GlobalKey _buttonKey = GlobalKey();

  Timer? _enterTimer;
  Timer? _focusTimer;
  bool _isMotionReduced = false;
  File? _photo;
  int _matches = 0;

  /// A name pre-filled from the query is not one the user has committed to,
  /// so it does not earn the no-photo advisory. Typing one does.
  bool _hasTypedName = false;

  bool get _canAdd => _name.text.trim().isNotEmpty;
  bool get _showsNoPhotoHint => _hasTypedName && _canAdd && _photo == null;

  Animation<double> _seg(double begin, double end) => CurvedAnimation(
    parent: _enter,
    curve: Interval(
      begin.clamp(0, 1),
      end.clamp(0, 1),
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_revealFocusedField);
    _specFocus.addListener(_revealFocusedField);
    _focusTimer = Timer(_focusDelay, () {
      // A user who tapped a field before the keyboard was due keeps it.
      final nodes = [_searchFocus, _nameFocus, _specFocus];
      if (nodes.any((node) => node.hasFocus)) return;
      (_canAdd ? _specFocus : _nameFocus).requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The keyboard rising or changing height moves the button block.
    _revealFocusedField();
    final isReduced = MediaQuery.disableAnimationsOf(context);
    if (_enterTimer != null && isReduced == _isMotionReduced) return;
    _isMotionReduced = isReduced;
    _enter.duration = isReduced ? _reducedDuration : _enterDuration;
    _enterTimer?.cancel();
    _enterTimer = Timer(
      isReduced ? _reducedEnterDelay : _enterDelay,
      _enter.forward,
    );
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _focusTimer?.cancel();
    for (final anim in [
      _rule,
      _headline,
      _body,
      _photoIn,
      _bottom,
      ..._fields,
    ]) {
      (anim as CurvedAnimation).dispose();
    }
    _enter.dispose();
    _scroll.dispose();
    for (final controller in [_search, _name, _spec]) {
      controller.dispose();
    }
    for (final node in [_searchFocus, _nameFocus, _specFocus]) {
      node.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final matches = query.trim().isEmpty
        ? 0
        : widget.countLibraryMatches(query);
    if (matches != _matches) setState(() => _matches = matches);
  }

  /// Scrolls the focused field clear of the pinned button block and the
  /// keyboard under it.
  ///
  /// The page's viewport runs the full height of the screen, so the text
  /// field's own reveal counts a field hidden behind the block as on screen
  /// and leaves it there — worse, its reveal re-targets the current offset,
  /// which cancels any scroll already under way and reads as a jump back.
  /// So this runs a frame after that reveal, measured once layout and the
  /// insets have landed.
  void _revealFocusedField() {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!mounted) return;
      binding
        ..addPostFrameCallback((_) => _scrollFocusedFieldClear())
        ..scheduleFrame();
    });
  }

  void _scrollFocusedFieldClear() {
    if (!mounted || !_scroll.hasClients) return;
    final rowKey = _nameFocus.hasFocus
        ? _nameRowKey
        : _specFocus.hasFocus
        ? _specRowKey
        : null;
    final screen = context.findRenderObject();
    final row = rowKey?.currentContext?.findRenderObject();
    // A hidden return bar still holds its room; only what shows is in the way.
    final blockKey = _matches > 0 ? _returnBarKey : _buttonKey;
    final block = blockKey.currentContext?.findRenderObject();
    if (row is! RenderBox || block is! RenderBox) return;
    final rowTop = row.localToGlobal(Offset.zero, ancestor: screen).dy;
    final clearance =
        block.localToGlobal(Offset.zero, ancestor: screen).dy - _revealGap;
    final overlap = rowTop + row.size.height - clearance;
    final delta = overlap > 0
        ? overlap
        : math.min(0.0, rowTop - _pagePadding.top);
    final position = _scroll.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    if (_isMotionReduced) {
      _scroll.jumpTo(target);
      return;
    }
    unawaited(
      _scroll.animateTo(
        target,
        duration: _revealDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _onNameChanged(String name) => setState(() => _hasTypedName = true);

  Future<void> _pickPhoto() async {
    final pick = widget.pickPhoto;
    if (pick == null) return;
    final photo = await pick();
    if (photo == null || !mounted) return;
    setState(() => _photo = photo);
  }

  void _submit() {
    if (!_canAdd) return;
    HapticFeedback.mediumImpact();
    widget.onAdd(
      ManualDraft(
        name: _name.text.trim(),
        spec: _spec.text.trim(),
        photo: _photo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final exit =
        ModalRoute.of(context)?.secondaryAnimation ??
        const AlwaysStoppedAnimation<double>(0);

    return Material(
      color: SpecColors.bg,
      // Replaces Material's typography rather than merging with it: its
      // default line height would stretch every block past the design.
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: SpecFonts.display,
          color: SpecColors.ink,
          decoration: TextDecoration.none,
        ),
        child: HeroMode(
          // Under Reduce Motion the commit is a plain cross-fade.
          enabled: !_isMotionReduced,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                controller: _scroll,
                padding: _pagePadding.copyWith(
                  bottom: _pagePadding.bottom + keyboard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fadeOnExit(exit, _exitAll, _buildHeader()),
                    const SizedBox(height: _blockGap),
                    _fadeOnExit(exit, _exitAll, _buildSearch()),
                    const SizedBox(height: _blockGap + _nudge),
                    _fadeOnExit(exit, _exitAll, _buildVerdict()),
                    const SizedBox(height: _blockGap + _nudge),
                    _buildPhotoCard(exit),
                    const SizedBox(height: _blockGap),
                    _buildFields(exit),
                    const SizedBox(height: _hintGap),
                    _fadeOnExit(exit, _exitAll, _buildHint()),
                  ],
                ),
              ),
              Positioned(
                left: _bottomInsets.left,
                right: _bottomInsets.right,
                bottom: _bottomInsets.bottom + keyboard,
                child: _fadeOnExit(exit, _exitAll, _buildBottomBlock()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Hero(
      tag: kAddStepHeaderTag,
      flightShuttleBuilder: keepTextStyleShuttle,
      child: SearchHeaderRow(
        label: widget.stepLabel,
        onCancel: () {
          HapticFeedback.lightImpact();
          widget.onCancel?.call();
        },
      ),
    );
  }

  Widget _buildSearch() {
    return LibrarySearchPill(
      controller: _search,
      focusNode: _searchFocus,
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildVerdict() {
    final hasQuery = widget.query.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _enterIn(
          _rule,
          0,
          const SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: ManualColors.ruleStrong),
          ),
        ),
        const SizedBox(height: _ruleToText),
        // Nothing failed on the way in through ADD YOUR OWN, so no count.
        if (hasQuery) ...[
          _enterIn(
            _rule,
            0,
            const Text('0 MATCHES IN LIBRARY', style: ManualText.matches),
          ),
          const SizedBox(height: _verdictGap),
        ],
        _enterIn(
          _headline,
          20,
          Text(
            hasQuery ? 'NOT IN\nTHE LIST.' : 'ADD YOUR\nOWN.',
            style: ManualText.verdict,
          ),
        ),
        const SizedBox(height: _verdictGap),
        _enterIn(
          _body,
          14,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _bodyMaxWidth),
            child: Text(
              hasQuery
                  ? 'Photograph it instead. SPEC keeps your own photo and '
                        'specs on this phone.'
                  : 'Photograph it and give it a name. SPEC keeps both on '
                        'this phone.',
              style: ManualText.body,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(Animation<double> exit) {
    final card = PhotoDropCard(
      photo: _photo,
      height: _photoHeight,
      borderRadius: manualPhotoRadius,
      chipFadeDuration: _chipFade,
      isMotionReduced: _isMotionReduced,
      onPick: () => unawaited(_pickPhoto()),
      onClear: () => setState(() => _photo = null),
    );
    return _fadeOnExitReduced(
      exit,
      AnimatedBuilder(
        animation: _enter,
        builder: (context, child) => Opacity(
          opacity: _opacityOf(_photoIn),
          child: Transform.translate(
            offset: Offset(0, _travelOf(_photoIn, 18)),
            child: Transform.scale(
              scale: _isMotionReduced ? 1 : 0.98 + 0.02 * _photoIn.value,
              child: child,
            ),
          ),
        ),
        child: Hero(
          tag: kManualPhotoTag,
          flightShuttleBuilder: manualPhotoShuttle(_photo),
          child: card,
        ),
      ),
    );
  }

  Widget _buildFields(Animation<double> exit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fadeOnExitReduced(
          exit,
          _enterIn(
            _fields[0],
            14,
            ManualFieldRow(
              key: _nameRowKey,
              label: 'NAME',
              placeholder: 'What is it called?',
              controller: _name,
              focusNode: _nameFocus,
              borderRadius: manualNameRadius,
              isMotionReduced: _isMotionReduced,
              onChanged: _onNameChanged,
              onSubmitted: (_) => _specFocus.requestFocus(),
              valueWrapper: (value) => Hero(
                tag: kManualNameTag,
                flightShuttleBuilder: manualNameShuttle(_name.text),
                child: value,
              ),
            ),
          ),
        ),
        const SizedBox(height: _fieldGap),
        _enterIn(
          _fields[1],
          14,
          ManualFieldRow(
            key: _specRowKey,
            label: 'SPEC',
            placeholder: "Anything you'd forget",
            controller: _spec,
            focusNode: _specFocus,
            borderRadius: manualSpecRadius,
            capitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            isMotionReduced: _isMotionReduced,
            onSubmitted: (_) => _submit(),
            // Received, not dragged: the spec fades in place and reappears
            // in step 05 as a fresh element.
            valueWrapper: (value) => _fadeOnExit(exit, _exitSpec, value),
          ),
        ),
      ],
    );
  }

  Widget _buildHint() {
    final isShown = _showsNoPhotoHint;
    return ExcludeSemantics(
      excluding: !isShown,
      child: AnimatedOpacity(
        opacity: isShown ? 1 : 0,
        duration: isShown ? _hintIn : _hintOut,
        curve: Curves.easeOut,
        child: const Text(
          'NO PHOTO — THIS OBJECT WILL SHOW A BLANK TILE',
          style: ManualText.noPhotoHint,
        ),
      ),
    );
  }

  Widget _buildBottomBlock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManualReturnBar(
          key: _returnBarKey,
          matches: _matches,
          isMotionReduced: _isMotionReduced,
          onTap: () => widget.onReturnToLibrary?.call(_search.text),
        ),
        const SizedBox(height: _bottomGap),
        _enterIn(
          _bottom,
          14,
          Column(
            key: _buttonKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListenableBuilder(
                listenable: _name,
                builder: (context, _) => ManualAddButton(
                  isEnabled: _canAdd,
                  isMotionReduced: _isMotionReduced,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: _bottomGap),
              // Full opacity whatever the button's state: the privacy promise
              // is not conditional.
              const Text(
                'NOTHING LEAVES THIS PHONE',
                textAlign: TextAlign.center,
                style: SpecText.frameCaption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Under reduced motion every element shares one plain fade.
  double _opacityOf(Animation<double> segment) =>
      _isMotionReduced ? _enter.value : segment.value;

  double _travelOf(Animation<double> segment, double distance) =>
      _isMotionReduced ? 0 : distance * (1 - segment.value);

  Widget _enterIn(Animation<double> segment, double rise, Widget child) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) => Opacity(
        opacity: _opacityOf(segment),
        child: Transform.translate(
          offset: Offset(0, _travelOf(segment, rise)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// Fades as step 05 covers this screen, over the first [span] of its push.
  /// Under reduced motion the whole push is the cross-fade.
  Widget _fadeOnExit(Animation<double> exit, double span, Widget child) {
    return AnimatedBuilder(
      animation: exit,
      builder: (context, child) {
        final end = _isMotionReduced ? 1.0 : span;
        final t = (exit.value / end).clamp(0.0, 1.0);
        return Opacity(opacity: 1 - t, child: child);
      },
      child: child,
    );
  }

  /// The heroes fly rather than fade — unless Reduce Motion grounded them.
  Widget _fadeOnExitReduced(Animation<double> exit, Widget child) =>
      _isMotionReduced ? _fadeOnExit(exit, 1, child) : child;
}

/// `moka pot gasket` → `Moka pot gasket`.
String sentenceCase(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}
