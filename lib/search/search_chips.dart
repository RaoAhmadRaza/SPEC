import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/search/search_tokens.dart';

/// The tapped chip's border flashes lime before the new results arrive.
const _flashDuration = Duration(milliseconds: 160);

const _chipPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 7);
const _chipGap = 8.0;

/// Recent queries, newest first. An escape hatch, not navigation.
class RecentChips extends StatelessWidget {
  const RecentChips({super.key, required this.queries, this.onTap});

  final List<String> queries;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _chipGap,
      runSpacing: _chipGap,
      children: [
        for (final query in queries)
          _RecentChip(query: query, onTap: () => onTap?.call(query)),
      ],
    );
  }
}

class _RecentChip extends StatefulWidget {
  const _RecentChip({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  State<_RecentChip> createState() => _RecentChipState();
}

class _RecentChipState extends State<_RecentChip> {
  bool _isFlashing = false;

  void _onTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _isFlashing = true);
    Future.delayed(_flashDuration, () {
      if (mounted) setState(() => _isFlashing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: _flashDuration,
        curve: Curves.easeOut,
        padding: _chipPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _isFlashing
                ? SearchColors.pillBorderFocused
                : SearchColors.chipBorder,
          ),
        ),
        child: Text(widget.query.toUpperCase(), style: SearchText.chip),
      ),
    );
  }
}
