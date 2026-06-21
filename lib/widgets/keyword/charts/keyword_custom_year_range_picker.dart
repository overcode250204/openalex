import 'package:flutter/material.dart';

class KeywordCustomYearRangePicker extends StatelessWidget {
  final int fromYear;
  final int toYear;
  final void Function(int fromYear, int toYear) onChanged;

  const KeywordCustomYearRangePicker({
    super.key,
    required this.fromYear,
    required this.toYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    // Generate a list of years from 1990 to current year
    final years = List<int>.generate(
      currentYear - 1990 + 1,
      (i) => currentYear - i,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildYearDropdown(
          context,
          fromYear,
          years,
          const Key('keyword_trend_start_year_dropdown'),
          (val) {
            if (val != null) {
              if (val > toYear) {
                onChanged(val, val);
              } else {
                onChanged(val, toYear);
              }
            }
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('-', style: TextStyle(color: Colors.grey)),
        ),
        _buildYearDropdown(
          context,
          toYear,
          years,
          const Key('keyword_trend_end_year_dropdown'),
          (val) {
            if (val != null) {
              if (val < fromYear) {
                onChanged(val, val);
              } else {
                onChanged(fromYear, val);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildYearDropdown(
    BuildContext context,
    int selectedValue,
    List<int> years,
    Key key,
    ValueChanged<int?> onChanged,
  ) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<int>(
        key: key,
        value: years.contains(selectedValue) ? selectedValue : years.first,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
        items: years.map((year) {
          return DropdownMenuItem<int>(
            value: year,
            child: Text(year.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
