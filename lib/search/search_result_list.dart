import 'package:flutter/widgets.dart';

import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_result_row.dart';
import 'package:spec/widgets/keyed_reflow.dart';

/// §5.4: rows move over 260ms, leave over 180ms, enter over 240ms staggered
/// by 30ms.
const _motion = ReflowMotion(
  move: Duration(milliseconds: 260),
  enter: Duration(milliseconds: 240),
  exit: Duration(milliseconds: 180),
  stagger: Duration(milliseconds: 30),
  enterOffset: 12,
  exitScale: 0.97,
);

/// The result list. A row that survives a re-query travels to its new index.
class SearchResultList extends StatelessWidget {
  const SearchResultList({super.key, required this.results, this.onOpen});

  final List<SearchResult> results;
  final ValueChanged<SearchResult>? onOpen;

  @override
  Widget build(BuildContext context) {
    return KeyedReflow<SearchResult>(
      items: results,
      keyOf: (result) => result.id,
      cellHeight: kSearchRowHeight,
      motion: _motion,
      itemBuilder: (context, result, index, isLeaving) => SearchResultRow(
        result: result,
        // A row on its way out gives up the lime, so the best match is never
        // lime twice while the old top row fades.
        isBest: index == 0 && !isLeaving,
        onTap: () => onOpen?.call(result),
      ),
    );
  }
}
