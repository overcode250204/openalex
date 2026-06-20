import 'package:flutter/material.dart';

class KeywordTrendLegendChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isVisible;
  final VoidCallback onToggle;

  const KeywordTrendLegendChip({
    super.key,
    required this.label,
    required this.color,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${isVisible ? 'Hide' : 'Show'} $label series',
      button: true,
      enabled: true,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isVisible ? color.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
              color: isVisible ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isVisible ? color : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isVisible ? FontWeight.w600 : FontWeight.w400,
                  color: isVisible ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
