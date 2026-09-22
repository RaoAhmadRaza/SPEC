import 'package:flutter/widgets.dart';

import 'package:spec/search/search_chips.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _blockGap = 22.0;
const _labelToBody = 12.0;
const _titleToBody = 10.0;
const _bodyToButton = 20.0;
const _buttonToChips = 18.0;

/// The copy under a `NOTHING` headline never runs wider than this.
const _bodyMaxWidth = 300.0;

const _buttonHeight = 56.0;

/// A quoted query longer than this is elided inside the quotes.
const _quotedQueryLimit = 24;

/// §4.1 — focused, nothing typed yet. Nothing has failed, so there is no
/// "no results" copy anywhere on it.
class SearchRestingBody extends StatelessWidget {
  const SearchRestingBody({
    super.key,
    required this.recents,
    required this.zones,
    this.onRecent,
    this.onZone,
  });

  final List<String> recents;
  final List<SearchZone> zones;
  final ValueChanged<String>? onRecent;
  final ValueChanged<SearchZone>? onZone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recents.isNotEmpty) ...[
          const SizedBox(height: _blockGap),
          const _SectionLabel('RECENT'),
          const SizedBox(height: _labelToBody),
          RecentChips(queries: recents, onTap: onRecent),
        ],
        if (zones.isNotEmpty) ...[
          const SizedBox(height: _blockGap),
          const _SectionLabel('BROWSE BY ZONE'),
          const SizedBox(height: _labelToBody),
          for (final zone in zones)
            _ZoneRow(zone: zone, onTap: () => onZone?.call(zone)),
        ],
      ],
    );
  }
}

/// §4.2 — a query that finds nothing. One action, and no spelling hint: the
/// search is fuzzy already, so the answer is to add the object.
class SearchNoMatchBody extends StatelessWidget {
  const SearchNoMatchBody({
    super.key,
    required this.query,
    required this.recents,
    this.onAdd,
    this.onRecent,
  });

  final String query;
  final List<String> recents;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onRecent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: _blockGap),
        const _EmptyTitle('NOTHING\nMATCHES.'),
        const SizedBox(height: _titleToBody),
        _EmptyBody(
          'No object in your archive matches "${elideQuery(query)}". '
          'You can add it now.',
        ),
        const SizedBox(height: _bodyToButton),
        SearchLimeButton(label: 'ADD IT INSTEAD', onTap: onAdd),
        if (recents.isNotEmpty) ...[
          const SizedBox(height: _buttonToChips),
          RecentChips(queries: recents, onTap: onRecent),
        ],
      ],
    );
  }
}

/// §4.3 — a zone that exists and holds nothing. No recent chips: they would
/// be out of scope and confusing.
class SearchZoneEmptyBody extends StatelessWidget {
  const SearchZoneEmptyBody({super.key, required this.zone, this.onAdd});

  final String zone;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: _blockGap),
        const _EmptyTitle('NOTHING\nHERE YET.'),
        const SizedBox(height: _titleToBody),
        const _EmptyBody(
          'This zone is empty. Add the first thing you want to '
          'remember about it.',
        ),
        const SizedBox(height: _bodyToButton),
        SearchLimeButton(label: 'ADD TO ${zone.toUpperCase()}', onTap: onAdd),
      ],
    );
  }
}

/// Truncates inside the quotes rather than letting the sentence run away.
String elideQuery(String query) => query.characters.length > _quotedQueryLimit
    ? '${query.characters.take(_quotedQueryLimit)}…'
    : query;

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label, style: SearchText.count),
  );
}

class _EmptyTitle extends StatelessWidget {
  const _EmptyTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: SearchText.emptyTitle),
  );
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _bodyMaxWidth),
      child: Text(text, style: SearchText.emptyBody),
    ),
  );
}

/// One line of `BROWSE BY ZONE`. Tapping it runs a zone-scoped search.
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone, required this.onTap});

  final SearchZone zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: SearchColors.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                zone.name,
                style: SearchText.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${zone.count}', style: SearchText.zoneCount),
          ],
        ),
      ),
    );
  }
}

/// The one action an empty state offers.
class SearchLimeButton extends StatelessWidget {
  const SearchLimeButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: _buttonHeight),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: SpecColors.accent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: SearchColors.buttonShadow,
              blurRadius: 34,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: SearchText.button,
        ),
      ),
    );
  }
}
