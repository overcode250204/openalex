import 'package:flutter/material.dart';

enum KeywordTrendRange { fiveYears, tenYears, all }

class KeywordChartPeriodSelector extends StatelessWidget {
  final KeywordTrendRange selectedRange;
  final ValueChanged<KeywordTrendRange> onChanged;

  const KeywordChartPeriodSelector({
    super.key,
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<KeywordTrendRange>(
      value: selectedRange,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
      items: const [
        DropdownMenuItem(
          value: KeywordTrendRange.fiveYears,
          child: Text('5 Years'),
        ),
        DropdownMenuItem(
          value: KeywordTrendRange.tenYears,
          child: Text('10 Years'),
        ),
        DropdownMenuItem(value: KeywordTrendRange.all, child: Text('All')),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
