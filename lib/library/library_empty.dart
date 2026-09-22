import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/library/library_chrome.dart';
import 'package:spec/library/library_tokens.dart';
import 'package:spec/search/search_empty.dart';
import 'package:spec/theme/spec_tokens.dart';

/// The body sits 22 below the rule row. The grid above it collapses to
/// nothing but still takes the column's 14, so the body adds the rest.
const _blockGap = 22.0 - 14.0;
const _titleToBody = 10.0;
const _bodyToButton = 20.0;
const _bodyToShowAll = 16.0;
const _bodyMaxWidth = 300.0;

/// §4.1 — a query the library does not know. The bridge to the manual path,
/// so it offers exactly one action and no spelling hint: the library is a
/// fixed set, and a miss is a fact rather than a typo.
class LibraryNoMatchBody extends StatelessWidget {
  const LibraryNoMatchBody({
    super.key,
    required this.librarySize,
    this.onPhotograph,
  });

  final int librarySize;
  final VoidCallback? onPhotograph;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: _blockGap),
        const _Title('NOT IN\nTHE LIST.'),
        const SizedBox(height: _titleToBody),
        _Body(
          'The library has $librarySize common things. Yours isn\'t one of '
          'them — photograph it instead.',
        ),
        const SizedBox(height: _bodyToButton),
        Squeeze(
          onTap: onPhotograph,
          child: const SearchLimeButton(label: 'PHOTOGRAPH IT'),
        ),
      ],
    );
  }
}

/// §4.2 — a category with nothing in it. Defensive: the bundled categories
/// are never empty, only a user-defined one could be.
class LibraryEmptyCategoryBody extends StatelessWidget {
  const LibraryEmptyCategoryBody({super.key, this.onShowAll});

  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: _blockGap),
        const _Title('NOTHING\nIN HERE.'),
        const SizedBox(height: _titleToBody),
        const _Body('No library objects in this category.'),
        const SizedBox(height: _bodyToShowAll),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onShowAll?.call();
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: LibraryColors.showAllFill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: LibraryColors.showAllBorder),
            ),
            child: const Text('SHOW ALL', style: LibraryText.showAll),
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: LibraryText.emptyTitle,
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _bodyMaxWidth),
      child: Text(text, style: SpecText.bodyCopy),
    ),
  );
}
