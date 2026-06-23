import 'package:flutter/material.dart';

const List<int> keywordTopNOptions = [5, 10, 15, 20];

class KeywordTopNSelector extends StatelessWidget {
  final int selectedTopN;
  final ValueChanged<int> onChanged;

  const KeywordTopNSelector({
    super.key,
    required this.selectedTopN,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Number of keywords to show',
      child: Container(
        height: 34,
        padding: const EdgeInsets.only(left: 10, right: 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedTopN,
            isDense: true,
            borderRadius: BorderRadius.circular(10),
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
            items: keywordTopNOptions
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text('Top $value'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}
