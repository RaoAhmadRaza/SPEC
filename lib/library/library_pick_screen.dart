import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import 'package:spec/home/home_icons.dart';
import 'package:spec/library/library_cell.dart';
import 'package:spec/library/library_chrome.dart';
import 'package:spec/library/library_empty.dart';
import 'package:spec/library/library_models.dart';
import 'package:spec/library/library_tokens.dart';
import 'package:spec/search/search_header.dart';
import 'package:spec/search/search_pill.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';
import 'package:spec/widgets/keyed_reflow.dart';
import 'package:spec/widgets/square_caret_field.dart';

/// 108 at the bottom clears the floating bar.
const _pagePadding = EdgeInsets.fromLTRB(18, 56, 18, 108);
const _columnGap = 14.0;
const _headlineMargin = 2.0;

const _pillPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
const _pillBlur = 15.0;
const _glyphSize = 19.0;
const _glyphGap = 12.0;

const _gridColumns = 3;
const _gridGap = 9.0;

const _barInset = 16.0;
const _barBottom = 24.0;

/// Library-wide, not app search: the library is in memory, so it can answer
/// faster than a database read.
const _debounceDelay = Duration(milliseconds: 100);

const _borderDuration = Duration(milliseconds: 220);
const _barFadeDuration = Duration(milliseconds: 200);

const _enterDuration = Duration(milliseconds: 720);
const _reducedEnterDuration = Duration(milliseconds: 200);

/// The content waits for the route to be 35% of the way up (of 420ms).
const _enterDelay = Duration(milliseconds: 150);

/// Past the first twelve cells everything shares the twelfth's timing, so a
/// scroll straight after presentation never finds a cell mid-entrance.
const _staggeredCells = 12;

/// How long a picked cell holds its cleared spec before it can show again.
const _pickHold = Duration(milliseconds: 600);

const _bodyInDuration = Duration(milliseconds: 300);
const _bodyOutDuration = Duration(milliseconds: 160);
const _bodyInDelay = 80 / 300;
const _bodyOffset = 16.0;

/// §5.3: cells leave over 160ms, travel over 260ms, enter over 220ms
/// staggered by 25ms.
const _reflow = ReflowMotion(
  move: Duration(milliseconds: 260),
  enter: Duration(milliseconds: 220),
  exit: Duration(milliseconds: 160),
  stagger: Duration(milliseconds: 25),
  enterOffset: 12,
  exitScale: 0.96,
);

enum _Body { grid, noMatch, emptyCategory }

/// Screen 07. Step 1 of the add flow: pick a shape from the bundled library
/// rather than typing one.
class LibraryPickScreen extends StatefulWidget {
  const LibraryPickScreen({
    super.key,
    required this.items,
    required this.onPick,
    this.stepLabel = 'STEP 1 / 3',
    this.categories = kLibraryCategories,
    this.onCancel,
    this.onAddOwn,
    this.initialQuery = '',
  });

  /// The whole bundled library, already in memory.
  final List<LibraryItem> items;

  /// Fired with the picked shape. Its example spec is never carried.
  final ValueChanged<LibraryItem> onPick;

  /// `STEP 1 / 3` on the library path, `STEP 1 / 2` when the caller skipped
  /// the type step.
  final String stepLabel;

  final List<String> categories;
  final VoidCallback? onCancel;

  /// `ADD YOUR OWN` and `PHOTOGRAPH IT`, with whatever was typed.
  final ValueChanged<String>? onAddOwn;

  /// Carried in from a search that found nothing, so the grid opens already
  /// filtered to it — or straight on `PHOTOGRAPH IT` when nothing matches.
  final String initialQuery;

  @override
  State<LibraryPickScreen> createState() => _LibraryPickScreenState();
}

class _LibraryPickScreenState extends State<LibraryPickScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );

  /// 0 is white, 1 is lime. The pill arrives unfocused.
  late final AnimationController _border = AnimationController(
    vsync: this,
    duration: _borderDuration,
  );

  late final TextEditingController _field = TextEditingController(
    text: widget.initialQuery,
  );
  final FocusNode _focus = FocusNode();

  late final Animation<double> _header = _seg(0.00, 0.26);
  late final Animation<double> _headline = _seg(0.06, 0.50);
  late final Animation<double> _pill = _seg(0.18, 0.58);
  late final Animation<double> _rule = _seg(0.36, 0.62);
  late final Animation<double> _bar = _seg(0.60, 1.00);
  late final List<Animation<double>> _chips = [
    for (var i = 0; i < widget.categories.length; i++)
      _seg(0.28 + i * 0.035, 0.28 + i * 0.035 + 0.30),
  ];
  late final List<Animation<double>> _cells = [
    for (var i = 0; i < _staggeredCells; i++)
      _seg(0.40 + i * 0.03, 0.40 + i * 0.03 + 0.34),
  ];

  late String _category = widget.categories.first;
  late List<LibraryItem> _shown = _filter(_appliedQuery);

  /// The query [_shown] was filtered with, which lags the field by the
  /// debounce. The empty states read this, not the field, so a half-typed
  /// word never flashes `NOT IN THE LIST.`
  late String _appliedQuery = widget.initialQuery.trim();

  Timer? _debounce;
  Timer? _enterTimer;
  Timer? _pickTimer;
  String? _pickedId;

  bool _isMotionReduced = false;
  bool? _appliedMotionPreference;

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
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isReduced = MediaQuery.disableAnimationsOf(context);
    if (isReduced == _appliedMotionPreference) return;
    final isFirst = _appliedMotionPreference == null;
    _appliedMotionPreference = isReduced;
    _isMotionReduced = isReduced;
    _enter.duration = isReduced ? _reducedEnterDuration : _enterDuration;
    if (!isFirst) return;
    if (isReduced) {
      unawaited(_enter.forward());
    } else {
      _enterTimer = Timer(_enterDelay, () {
        if (mounted) unawaited(_enter.forward());
      });
    }
  }

  @override
  void didUpdateWidget(LibraryPickScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      _shown = _filter(_appliedQuery);
    }
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      unawaited(_border.forward());
    } else {
      unawaited(_border.reverse());
    }
  }

  List<LibraryItem> _filter(String query) =>
      filterLibrary(widget.items, category: _category, query: query);

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      final query = _field.text.trim();
      setState(() {
        _appliedQuery = query;
        _shown = _filter(query);
      });
    });
  }

  void _onCategory(String category) {
    if (category == _category) return;
    setState(() {
      _category = category;
      _shown = _filter(_appliedQuery);
    });
  }

  void _onPick(LibraryItem item) {
    _focus.unfocus();
    setState(() => _pickedId = item.id);
    _pickTimer?.cancel();
    _pickTimer = Timer(_pickHold, () {
      if (mounted) setState(() => _pickedId = null);
    });
    widget.onPick(item);
  }

  void _onAddOwn() => widget.onAddOwn?.call(_field.text.trim());

  @override
  void dispose() {
    _debounce?.cancel();
    _enterTimer?.cancel();
    _pickTimer?.cancel();
    for (final animation in [
      _header,
      _headline,
      _pill,
      _rule,
      _bar,
      ..._chips,
      ..._cells,
    ]) {
      (animation as CurvedAnimation).dispose();
    }
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _field.dispose();
    _enter.dispose();
    _border.dispose();
    super.dispose();
  }

  _Body get _body {
    if (_shown.isNotEmpty) return _Body.grid;
    return _appliedQuery.isEmpty ? _Body.emptyCategory : _Body.noMatch;
  }

  String get _count => switch (_body) {
    _Body.grid =>
      'LIBRARY · ${_shown.length} ${_shown.length == 1 ? 'OBJECT' : 'OBJECTS'}',
    _Body.noMatch => 'LIBRARY · 0 MATCHES',
    _Body.emptyCategory => 'LIBRARY · 0 OBJECTS',
  };

  /// Fades a block in, and under full motion lifts and scales it as it comes.
  Widget _rise(
    Animation<double> animation,
    Widget child, {
    double dy = 0,
    double scaleFrom = 1,
  }) {
    if (_isMotionReduced) {
      return FadeTransition(opacity: animation, child: child);
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, inner) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, dy * (1 - t)),
            child: Transform.scale(
              scale: scaleFrom + (1 - scaleFrom) * t,
              child: inner,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final isBarVisible = _body != _Body.noMatch;

    // A Material ancestor for the text field, which asserts without one. Pushed
    // as a route, nothing above this screen provides it.
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: SpecFonts.display,
          color: SpecColors.ink,
          decoration: TextDecoration.none,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: SpecColors.bg),
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: _pagePadding.copyWith(
                bottom: _pagePadding.bottom + keyboard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildBlocks(),
              ),
            ),
            Positioned(
              left: _barInset,
              right: _barInset,
              bottom: _barBottom,
              child: _rise(
                _bar,
                // Hidden in the no-match state, where `PHOTOGRAPH IT` is already
                // the one way out.
                IgnorePointer(
                  ignoring: !isBarVisible,
                  child: AnimatedOpacity(
                    opacity: isBarVisible ? 1 : 0,
                    duration: _isMotionReduced
                        ? Duration.zero
                        : _barFadeDuration,
                    child: LibraryBottomBar(onAddOwn: _onAddOwn),
                  ),
                ),
                dy: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBlocks() => [
    _rise(
      _header,
      SearchHeaderRow(label: widget.stepLabel, onCancel: widget.onCancel),
    ),
    const SizedBox(height: _columnGap + _headlineMargin),
    _rise(
      _headline,
      const Text('WHAT\nIS IT?', style: LibraryText.headline),
      dy: 22,
    ),
    const SizedBox(height: _columnGap),
    _rise(_pill, _buildPill(), dy: 16, scaleFrom: 0.98),
    const SizedBox(height: _columnGap),
    LibraryFilterChips(
      categories: widget.categories,
      selected: _category,
      onSelect: _onCategory,
      wrapChip: (index, child) => _rise(_chips[index], child, dy: 12),
    ),
    const SizedBox(height: _columnGap),
    _rise(_rule, LibraryRuleRow(count: _count)),
    const SizedBox(height: _columnGap),
    KeyedReflow<LibraryItem>(
      items: _shown,
      keyOf: (item) => item.id,
      columns: _gridColumns,
      crossGap: _gridGap,
      mainGap: _gridGap,
      cellHeight: libraryCellHeight(context),
      motion: _reflow,
      itemBuilder: (context, item, index, isLeaving) => _rise(
        _cells[math.min(index, _staggeredCells - 1)],
        LibraryCell(
          item: item,
          index: index,
          isPicked: item.id == _pickedId,
          onTap: isLeaving ? null : () => _onPick(item),
        ),
        dy: 20,
        scaleFrom: 0.96,
      ),
    ),
    _buildBodyRegion(),
  ];

  Widget _buildPill() {
    return AnimatedBuilder(
      animation: _border,
      builder: (context, child) => SearchPillShell(
        borderColor: Color.lerp(
          SearchColors.pillBorderBlurred,
          SearchColors.pillBorderFocused,
          Curves.easeOut.transform(_border.value),
        )!,
        blur: _pillBlur,
        padding: _pillPadding,
        child: child!,
      ),
      // No waveform: that belongs to the app's own search. This field
      // searches bundled content, and the difference should be visible.
      child: Row(
        children: [
          const HomeIcon.search(size: _glyphSize, color: SpecColors.ink80),
          const SizedBox(width: _glyphGap),
          Expanded(
            child: SquareCaretField(
              controller: _field,
              focusNode: _focus,
              style: LibraryText.query,
              hint: 'Bulb, filter, tyre, cartridge...',
              hintStyle: LibraryText.hint,
              onChanged: _onQueryChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// The block below the grid, and the arrival and collapse between blocks.
  ///
  /// Reduce Motion draws it plainly: an [AnimatedSize] told to take no time
  /// still drives its controller from inside layout, which is not legal.
  Widget _buildBodyRegion() {
    final body = KeyedSubtree(key: ValueKey(_body), child: _buildBody());
    if (_isMotionReduced) return body;
    return AnimatedSize(
      duration: _bodyOutDuration,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: _bodyInDuration,
        reverseDuration: _bodyOutDuration,
        switchInCurve: const Interval(
          _bodyInDelay,
          1,
          curve: Curves.easeOutCubic,
        ),
        switchOutCurve: Curves.easeOut,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, inner) => Transform.translate(
              offset: Offset(0, _bodyOffset * (1 - animation.value)),
              child: inner,
            ),
          ),
        ),
        child: body,
      ),
    );
  }

  Widget _buildBody() => switch (_body) {
    _Body.grid => const SizedBox(width: double.infinity),
    _Body.noMatch => LibraryNoMatchBody(
      librarySize: widget.items.length,
      onPhotograph: _onAddOwn,
    ),
    _Body.emptyCategory => LibraryEmptyCategoryBody(
      onShowAll: () => _onCategory(kLibraryAll),
    ),
  };
}
