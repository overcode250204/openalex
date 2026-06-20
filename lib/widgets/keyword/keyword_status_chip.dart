import 'package:flutter/material.dart';

import '../../models/keyword/keyword_overview.dart';

class KeywordStatusChip extends StatelessWidget {
  final KeywordStatus status;

  const KeywordStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      KeywordStatus.hot => ('HOT', Colors.red),
      KeywordStatus.emerging => ('EMERGING', Colors.orange),
      KeywordStatus.stable => ('STABLE', Colors.blue),
      KeywordStatus.declining => ('DECLINING', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
