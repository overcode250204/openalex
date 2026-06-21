import 'package:flutter/material.dart';

class TopSelectorDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final List<int?> options;

  const TopSelectorDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = const [5, 10, 15, 20, 50, null],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Colors.grey.shade600,
          ),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: options.map((int? option) {
            final String label = option == null ? 'All' : 'Top $option';
            return DropdownMenuItem<int?>(
              value: option,
              child: Text(label),
            );
          }).toList(),
        ),
      ),
    );
  }
}
