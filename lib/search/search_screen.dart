import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField, TextInputAction;
import 'package:flutter/widgets.dart';

import 'package:spec/search/search_chips.dart';
import 'package:spec/search/search_empty.dart';
import 'package:spec/search/search_header.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_pill.dart';
import 'package:spec/search/search_result_list.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/search/search_waveform.dart';
import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

/// 56 top for the status bar and 18 either side, the same gutter Home uses —
/// which is what lets the pill fly between them without shifting sideways.
const _pageSide = 18.0;
const _pageTop = 56.0;

const _blockGap = 22.0;

/// The chips carry 2pt of their own margin on top of the block gap.
const _listToChips = _blockGap + 2;

/// CSS `blur(30px)` is a 15pt sigma.
const _pillBlur = 15.0;

const _borderDuration = Duration(milliseconds: 220);

/// Long enough that a fast typist runs one query, short enough that the
/// results feel like they are keeping up.
const _debounceDelay = Duration(milliseconds: 120);

/// The waveform settles this long after the last keystroke.
const _settleDelay = Duration(milliseconds: 300);

/// The screen's own content arrives over the back two thirds of the flight.
const _entranceStart = 0.35;
const _entranceOffset = 14.0;

const _bodyInDuration = Duration(milliseconds: 300);
const _bodyOutDuration = Duration(milliseconds: 200);

/// The empty block waits for the last row to leave before it arrives.
const _bodyInDelay = 80 / 300;
const _bodyOffset = 16.0;

/// Which block sits below the count row.
enum _Body { resting, results, noMatch, zoneEmpty }

/// Screen 02. One canvas: the header and the pill are identical in every
/// state, and only the region below the count row changes.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.runSearch,
    this.scope,
    this.isListingAll = false,
    this.initialQuery = '',
    this.recents = const [],
    this.zones = const [],
    this.counts = ArchiveCounts.empty,
    this.onCancel,
    this.onQueryRun,
    this.onOpen,
    this.onZone,
    this.onClearScope,
    this.onAdd,
  });

  final SearchRunner runSearch;

  /// Non-null narrows every query to one zone.
  final String? scope;

  /// SEE ALL: a blank query lists the whole archive, newest first, and typing
  /// filters it like any other search.
  final bool isListingAll;

  final String initialQuery;

  /// Newest first, already capped by the caller.
  final List<String> recents;

  final List<SearchZone> zones;
  final ArchiveCounts counts;

  final VoidCallback? onCancel;

  /// Fired when a query is actually used — submitted, opened or added — so
  /// the caller can remember it. Never per keystroke: that would fill the
  /// recents with every prefix on the way to the word.
  final ValueChanged<String>? onQueryRun;

  final ValueChanged<SearchResult>? onOpen;
  final ValueChanged<SearchZone>? onZone;
  final VoidCallback? onClearScope;

  /// Opens the add flow with the query pre-filled.
  final ValueChanged<String>? onAdd;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _field = TextEditingController(
    text: widget.initialQuery,
  );
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  /// 1 is lime. The pill lands focused, so it starts there.
  late final AnimationController _border = AnimationController(
    vsync: this,
    duration: _borderDuration,
    value: 1,
  );

  Timer? _debounce;
  Timer? _settle;

  SearchResults _results = SearchResults.none;
  bool _isQuerying = false;
  bool _hasSettled = false;

  /// The run this state belongs to. A slower earlier query must not overwrite
  /// the results of a later one.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _focus
      ..addListener(_onFocusChanged)
      ..requestFocus();
    _scroll.addListener(_onScroll);
    // A scope, SEE ALL or a pre-filled query means results are owed on
    // arrival.
    if (_isOwedResults) _run(_query);
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The runner arrives asynchronously the first time, and again whenever
    // the archive changes. Whatever was owed on arrival is owed again.
    final isRunnerNew = oldWidget.runSearch != widget.runSearch;
    if (isRunnerNew && _isOwedResults) _run(_query);
  }

  String get _query => _field.text.trim();

  bool get _isOwedResults =>
      widget.scope != null || widget.isListingAll || _query.isNotEmpty;

  bool get _isMotionReduced => MediaQuery.disableAnimationsOf(context);

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      _border.forward();
    } else {
      _border.reverse();
    }
  }

  /// Scrolling the list dismisses the keyboard, which blurs the pill.
  void _onScroll() {
    if (_scroll.position.isScrollingNotifier.value && _focus.hasFocus) {
      _focus.unfocus();
    }
  }

  void _onChanged(String _) {
    setState(() {
      _isQuerying = true;
      _hasSettled = false;
    });
    _debounce?.cancel();
    _settle?.cancel();
    _debounce = Timer(_debounceDelay, () => _run(_query));
    _settle = Timer(_settleDelay, () {
      if (mounted) setState(() => _isQuerying = false);
    });
  }

  Future<void> _run(String query) async {
    final generation = ++_generation;
    final results = await widget.runSearch(query);
    if (!mounted || generation != _generation) return;
    setState(() {
      _results = results;
      _hasSettled = true;
    });
  }

  void _remember() {
    if (_query.isNotEmpty) widget.onQueryRun?.call(_query);
  }

  void _open(SearchResult result) {
    _remember();
    widget.onOpen?.call(result);
  }

  void _add() {
    _remember();
    widget.onAdd?.call(_query);
  }

  void _useQuery(String query) {
    _field
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    _focus.requestFocus();
    _onChanged(query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _settle?.cancel();
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _field.dispose();
    _border.dispose();
    super.dispose();
  }

  _Body get _body {
    if (_results.matches.isNotEmpty) return _Body.results;
    if (widget.scope != null && _query.isEmpty) return _Body.zoneEmpty;
    // Nothing has failed until a query has actually come back empty.
    if (_query.isNotEmpty && _hasSettled) return _Body.noMatch;
    return _Body.resting;
  }

  WaveformState get _waveformState {
    if (_query.isEmpty) return WaveformState.resting;
    return _isQuerying ? WaveformState.querying : WaveformState.settled;
  }

  String get _countLabel => switch (_body) {
    // SEE ALL with nothing typed is the archive, not a set of matches.
    _Body.results when widget.isListingAll && _query.isEmpty =>
      widget.counts.label,
    _Body.results => _matchCount(_results.matches.length),
    _Body.noMatch => _matchCount(0),
    _Body.zoneEmpty => '0 IN THIS ZONE',
    _Body.resting => widget.counts.label,
  };

  String? get _timingLabel => switch (_body) {
    _Body.results || _Body.noMatch => _results.timing,
    _Body.zoneEmpty || _Body.resting => null,
  };

  static String _matchCount(int n) => n == 1 ? '1 MATCH' : '$n MATCHES';

  String get _hint => switch (widget.scope) {
    final String zone => 'Search ${zone.toLowerCase()}...',
    null => 'Search your stuff...',
  };

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

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
        child: ColoredBox(
          color: SpecColors.bg,
          child: Padding(
            // The whole region ends at the keyboard rather than only the
            // scroll view padding around it. The pill holds the focused
            // field, so it has to stay above the keyboard; padding the
            // scroller alone left it stranded underneath with the results
            // squeezed into what was left.
            padding: EdgeInsets.fromLTRB(
              _pageSide,
              SpecLayout.topInset(context, design: _pageTop),
              _pageSide,
              viewInsets,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SizedBox(
                  // A 54pt thumb an arm's length from a 26pt spec is not a
                  // result row, so the column is capped and centred.
                  width: math.min(
                    constraints.maxWidth,
                    SpecLayout.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The pill is the Hero, so it never fades or
                      // translates: it flies. Everything around it arrives.
                      _entrance(SearchHeaderRow(onCancel: widget.onCancel)),
                      const SizedBox(height: _blockGap),
                      _buildPill(),
                      const SizedBox(height: _blockGap),
                      Expanded(
                        child: _entrance(
                          SingleChildScrollView(
                            controller: _scroll,
                            padding: const EdgeInsets.only(bottom: _blockGap),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _buildBelowPill(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill() {
    return AnimatedBuilder(
      animation: _border,
      builder: (context, _) => _pillHero(
        SearchPillShell(
          borderColor: Color.lerp(
            SearchColors.pillBorderBlurred,
            SearchColors.pillBorderFocused,
            _border.value,
          )!,
          blur: _pillBlur,
          flightChild: SearchPillContent(
            scope: widget.scope,
            field: Text(
              _query.isEmpty ? _hint : _query,
              style: _query.isEmpty ? SearchText.hint : SearchText.query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            waveform: kFlightWaveform,
          ),
          child: SearchPillContent(
            scope: widget.scope,
            onClearScope: widget.onClearScope,
            field: TextField(
              controller: _field,
              focusNode: _focus,
              onChanged: _onChanged,
              style: SearchText.query,
              // A square lime bar, not the rounded iOS default.
              cursorColor: SpecColors.accent,
              cursorWidth: 2,
              cursorHeight: 20,
              cursorRadius: Radius.zero,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _remember(),
              decoration: InputDecoration.collapsed(
                hintText: _hint,
                hintStyle: SearchText.hint,
              ),
            ),
            waveform: SearchWaveform(state: _waveformState),
          ),
        ),
      ),
    );
  }

  /// A scoped search's zone name is already a Hero, flying in from its
  /// Collections row, and a Hero inside a Hero asserts. Scoped search is
  /// reached from a Collections row or a Home zone chip, and neither is a pill
  /// to fly from.
  Widget _pillHero(SearchPillShell shell) =>
      widget.scope == null ? searchPillHero(shell: shell) : shell;

  List<Widget> _buildBelowPill() => [
    SearchCountRow(count: _countLabel, timing: _timingLabel),
    // No gap: the count row and the list are one continuous column.
    SearchResultList(results: _results.matches, onOpen: _open),
    _buildBodyRegion(),
    if (_body == _Body.results) ...[
      const SizedBox(height: _listToChips),
      RecentChips(queries: widget.recents, onTap: _useQuery),
    ],
  ];

  /// The block below the list, and the collapse and arrival between blocks.
  ///
  /// Reduce Motion draws it plainly: an [AnimatedSize] told to take no time
  /// still drives its controller from inside layout, which is not legal.
  Widget _buildBodyRegion() {
    if (_isMotionReduced) return _buildBody();
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
        transitionBuilder: _bodyTransition,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [...previous, ?current],
        ),
        child: KeyedSubtree(key: ValueKey(_body), child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() => switch (_body) {
    _Body.results => const SizedBox(width: double.infinity),
    _Body.resting => SearchRestingBody(
      recents: widget.recents,
      zones: widget.zones,
      onRecent: _useQuery,
      onZone: widget.onZone,
    ),
    _Body.noMatch => SearchNoMatchBody(
      query: _query,
      recents: widget.recents,
      onAdd: _add,
      onRecent: _useQuery,
    ),
    _Body.zoneEmpty => SearchZoneEmptyBody(
      zone: widget.scope ?? '',
      onAdd: _add,
    ),
  };

  Widget _bodyTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, inner) => Transform.translate(
          offset: Offset(0, _bodyOffset * (1 - animation.value)),
          child: inner,
        ),
      ),
    );
  }

  /// Fades and lifts a block over the back of the Hero flight.
  ///
  /// Driven by the route's own animation rather than a controller of its own,
  /// so the content cannot drift out of step with the pill.
  Widget _entrance(Widget child) {
    final route = ModalRoute.of(context)?.animation;
    if (route == null) return child;
    return AnimatedBuilder(
      animation: route,
      child: child,
      builder: (context, inner) {
        final t = Interval(
          _entranceStart,
          1,
          curve: Curves.easeOutCubic,
        ).transform(route.value.clamp(0, 1));
        if (_isMotionReduced) {
          return Opacity(opacity: route.value, child: inner);
        }
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, _entranceOffset * (1 - t)),
            child: inner,
          ),
        );
      },
    );
  }
}
