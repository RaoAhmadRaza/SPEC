import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/home/home_card.dart';
import 'package:spec/home/home_empty.dart';
import 'package:spec/home/home_header.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/home/home_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// 56 top for the status bar, 18 either side, and 112 at the bottom so the
/// last tile can scroll clear of the shell's floating bar and orb.
const _pagePadding = EdgeInsets.fromLTRB(18, 56, 18, 112);

/// The design's column gap, plus the per-block margins it sets on top.
const _gapHeaderToWordmark = 15.0;
const _gapWordmarkToTagline = 9.0;
const _gapTaglineToSearch = 15.0;
const _gapSearchToRail = 15.0;

/// `SEE ALL` carries 8pt of padding either side to make a real touch target,
/// so the two gaps around the rule give that height back.
const _seeAllPadding = 8.0;
const _gapRailToRule = 19.0 - _seeAllPadding;
const _gapRuleToGrid = 13.0 - _seeAllPadding;

/// The empty state has no section rule to head — there is no section yet —
/// so the composition follows the rail directly.
const _gapRailToEmpty = 24.0;

const _gridGap = 9.0;

/// At most three objects sit above the add card, which is what makes the
/// section read as "recently remembered" rather than "everything".
const _recentLimit = 3;

const _enterDuration = Duration(milliseconds: 820);
const _reducedEnterDuration = Duration(milliseconds: 200);

const _pressDuration = Duration(milliseconds: 110);
const _pressScale = 0.98;

const _hairlineDuration = Duration(milliseconds: 160);
const _hairlineOffset = 8.0;

/// The empty search pill is still visible, just plainly not usable.
const _emptySearchOpacity = 0.6;

/// The room behind the screen. It is already nearly black, so the scrim over
/// it only has to protect the mono lines, which are the first thing to become
/// unreadable over any texture.
const _scrimStops = [0.0, 0.42, 0.78, 1.0];
const _scrimAlphas = [0.58, 0.52, 0.74, 0.92];

final _scrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    for (final alpha in _scrimAlphas) SpecColors.bg.withValues(alpha: alpha),
  ],
  stops: _scrimStops,
);

/// Screen 01. An empty [objects] list drives the empty state, which is the
/// same canvas with the grid collapsed to one card — not a different screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.objects,
    this.categories = const [],
    this.onSearch,
    this.onSeeAll,
    this.onCategory,
    this.onNewZone,
    this.onObject,
    this.onObjectMenu,
    this.onAdd,
    this.onMenu,
  });

  final List<HomeObject> objects;
  final List<HomeCategory> categories;

  final VoidCallback? onSearch;
  final VoidCallback? onSeeAll;
  final ValueChanged<HomeCategory>? onCategory;
  final VoidCallback? onNewZone;
  final ValueChanged<HomeObject>? onObject;
  final ValueChanged<HomeObject>? onObjectMenu;
  final VoidCallback? onAdd;
  final VoidCallback? onMenu;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );

  late final Animation<double> _header = _seg(0.00, 0.26);
  late final Animation<double> _wordmark = _seg(0.06, 0.52);
  late final Animation<double> _tagline = _seg(0.22, 0.60);
  late final Animation<double> _search = _seg(0.28, 0.68);
  late final Animation<double> _rule = _seg(0.44, 0.70);
  late final List<Animation<double>> _sideLines = [
    for (var i = 0; i < 4; i++) _seg(0.14 + i * 0.04, 0.42 + i * 0.04),
  ];
  late final List<Animation<double>> _chips = [
    for (var i = 0; i < 6; i++) _seg(0.36 + i * 0.04, 0.66 + i * 0.04),
  ];
  late final List<Animation<double>> _tiles = [
    for (var i = 0; i < 4; i++) _seg(0.48 + i * 0.05, 0.84 + i * 0.05),
  ];

  /// The empty state's four blocks, which replace the grid.
  late final List<Animation<double>> _emptyBlocks = [
    for (var i = 0; i < 4; i++) _seg(0.48 + i * 0.05, 0.84 + i * 0.05),
  ];

  final ScrollController _scroll = ScrollController();

  bool _isMotionReduced = false;
  bool? _appliedMotionPreference;
  bool _isScrolled = false;
  int? _pressedTile;

  bool get _isEmpty => widget.objects.isEmpty;

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
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionPreference(MediaQuery.disableAnimationsOf(context));
  }

  void _syncMotionPreference(bool isReduced) {
    if (isReduced == _appliedMotionPreference) return;
    _appliedMotionPreference = isReduced;
    _isMotionReduced = isReduced;

    if (isReduced) {
      // The entrance becomes a plain fade. The layout is identical either way.
      _enter
        ..duration = _reducedEnterDuration
        ..forward();
      return;
    }

    _enter
      ..duration = _enterDuration
      ..forward();
  }

  void _onScroll() {
    final isScrolled = _scroll.offset > _hairlineOffset;
    if (isScrolled != _isScrolled) setState(() => _isScrolled = isScrolled);
  }

  @override
  void dispose() {
    for (final animation in [
      _header,
      _wordmark,
      _tagline,
      _search,
      _rule,
      ..._sideLines,
      ..._chips,
      ..._tiles,
      ..._emptyBlocks,
    ]) {
      (animation as CurvedAnimation).dispose();
    }
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _enter.dispose();
    super.dispose();
  }

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
      child: child,
    );
  }

  void _onTileDown(int index) => setState(() => _pressedTile = index);

  void _onTileUp() => setState(() => _pressedTile = null);

  void _openObject(HomeObject object) {
    HapticFeedback.selectionClick();
    widget.onObject?.call(object);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: SpecFonts.display,
        color: SpecColors.ink,
        decoration: TextDecoration.none,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: SpecColors.bg),
          Image.asset(
            'assets/images/home_bg.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(gradient: _scrim),
            child: const SizedBox.expand(),
          ),
          SingleChildScrollView(
            controller: _scroll,
            padding: _pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildBlocks(),
            ),
          ),
          // The only thing the scroll position changes.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isScrolled ? 1 : 0,
              duration: _hairlineDuration,
              child: const SizedBox(
                height: 1,
                child: ColoredBox(color: HomeColors.scrollHairline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBlocks() => [
    _rise(_header, HomeHeaderRow(onMenu: widget.onMenu ?? () {})),
    const SizedBox(height: _gapHeaderToWordmark),
    _rise(
      _wordmark,
      HomeWordmark(wrapLine: (index, child) => _rise(_sideLines[index], child)),
      dy: 22,
    ),
    const SizedBox(height: _gapWordmarkToTagline),
    _rise(
      _tagline,
      const Text(
        "REMEMBER THE THINGS\nYOU SHOULDN'T HAVE TO.",
        style: HomeText.tagline,
      ),
      dy: 12,
    ),
    const SizedBox(height: _gapTaglineToSearch),
    _rise(_search, _buildSearch(), dy: 16, scaleFrom: 0.98),
    const SizedBox(height: _gapSearchToRail),
    HomeCategoryRail(
      categories: widget.categories,
      onCategory: widget.onCategory ?? (_) {},
      onNewZone: widget.onNewZone ?? () {},
      wrapChip: (index, child) =>
          _rise(_chips[index.clamp(0, _chips.length - 1)], child, dy: 12),
    ),
    if (_isEmpty) ...[
      const SizedBox(height: _gapRailToEmpty),
      HomeEmptyState(
        onAdd: widget.onAdd ?? () {},
        wrap: (index, child) => _rise(_emptyBlocks[index], child, dy: 18),
      ),
    ] else ...[
      const SizedBox(height: _gapRailToRule),
      _rise(
        _rule,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: _seeAllPadding),
          child: HomeSectionRule(
            label: 'RECENTLY REMEMBERED',
            showSeeAll: true,
            onSeeAll: widget.onSeeAll,
          ),
        ),
      ),
      const SizedBox(height: _gapRuleToGrid),
      _buildGrid(),
    ],
  ];

  Widget _buildSearch() {
    final pill = HomeSearchPill(
      hint: _isEmpty ? 'Nothing saved yet' : 'Search your stuff...',
      onTap: widget.onSearch ?? () {},
    );
    if (!_isEmpty) return pill;
    // Present, still legible, and plainly not usable: there is nothing to
    // search until the first object exists.
    return IgnorePointer(
      child: Opacity(opacity: _emptySearchOpacity, child: pill),
    );
  }

  Widget _buildGrid() {
    final recent = widget.objects.take(_recentLimit).toList();
    final tiles = <Widget>[
      for (var i = 0; i < recent.length; i++)
        _tile(
          i,
          ObjectCard(
            object: recent[i],
            radius: kCardRadii[i],
            isLead: i == 0,
            onTap: () => _openObject(recent[i]),
            onMenu: () => widget.onObjectMenu?.call(recent[i]),
          ),
        ),
      _tile(recent.length, AddCard(onTap: widget.onAdd ?? () {})),
    ];

    return Column(
      children: [
        for (var row = 0; row * 2 < tiles.length; row++) ...[
          if (row > 0) const SizedBox(height: _gridGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tiles[row * 2]),
              const SizedBox(width: _gridGap),
              Expanded(
                child: row * 2 + 1 < tiles.length
                    ? tiles[row * 2 + 1]
                    : const SizedBox(height: kCardHeight),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Entrance stagger plus the press scale, which is the feedback before a
  /// card opens.
  Widget _tile(int index, Widget child) {
    final isPressed = _pressedTile == index;
    return _rise(
      _tiles[index.clamp(0, _tiles.length - 1)],
      Listener(
        onPointerDown: (_) => _onTileDown(index),
        onPointerUp: (_) => _onTileUp(),
        onPointerCancel: (_) => _onTileUp(),
        child: AnimatedScale(
          scale: isPressed && !_isMotionReduced ? _pressScale : 1,
          duration: _pressDuration,
          curve: Curves.easeOut,
          child: child,
        ),
      ),
      dy: 24,
      scaleFrom: 0.97,
    );
  }
}
