import 'package:flutter/widgets.dart';

import 'package:spec/home/home_glass.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/widgets/tap_target.dart';

const _pillBlur = 20.0;
const _pillSaturation = 1.8;
const _pillPadding = EdgeInsets.symmetric(horizontal: 15, vertical: 8);

/// The count number cross-fades; the timing beside it does not.
const _countFadeDuration = Duration(milliseconds: 160);

/// A glass label on the left, `CANCEL` on the right.
///
/// Search's `SPEC` and the add flow's `STEP 1 / 3` are the same row.
class SearchHeaderRow extends StatelessWidget {
  const SearchHeaderRow({super.key, this.label = 'SPEC', this.onCancel});

  final String label;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GlassSurface(
          borderRadius: BorderRadius.circular(999),
          blur: _pillBlur,
          saturation: _pillSaturation,
          fill: SearchColors.specPillFill,
          borderColor: SearchColors.specPillBorder,
          padding: _pillPadding,
          child: Text(label, style: SearchText.specPill),
        ),
        TapTarget(
          onTap: onCancel ?? () {},
          child: Container(
            padding: _pillPadding,
            decoration: BoxDecoration(
              color: SearchColors.cancelFill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SearchColors.cancelBorder),
            ),
            child: const Text('CANCEL', style: SearchText.cancelPill),
          ),
        ),
      ],
    );
  }
}

/// The mono rule between the pill and whatever is below it.
///
/// Every state draws this row; only what it says changes. [timing] is absent
/// wherever nothing has been measured.
class SearchCountRow extends StatelessWidget {
  const SearchCountRow({super.key, required this.count, this.timing});

  final String count;
  final String? timing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SearchColors.rule)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // The count yields first: the timing beside it is short and fixed,
          // and the two together overflowed a 320pt row at a raised scale.
          Flexible(
            child: AnimatedSwitcher(
              duration: _countFadeDuration,
              child: Text(
                count,
                key: ValueKey(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SearchText.count,
              ),
            ),
          ),
          // No animation: it is a measurement, and a tween would be a lie.
          if (timing case final String measured)
            Text(
              measured,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SearchText.timing,
            ),
        ],
      ),
    );
  }
}
