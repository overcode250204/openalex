import 'package:flutter/material.dart';

import '../../models/journal/journal_source.dart';
import 'metric_row.dart';

class JournalSourceCard extends StatelessWidget {
  final JournalSource journal;
  final bool isSelected;
  final VoidCallback onSelect;

  const JournalSourceCard({
    super.key,
    required this.journal,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    journal.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(journal.type),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            MetricRow(
              icon: Icons.confirmation_number_outlined,
              label: 'ISSN-L',
              value: journal.displayIssnL,
            ),
            MetricRow(
              icon: Icons.article_outlined,
              label: 'Works',
              value: journal.worksCount.toString(),
            ),
            MetricRow(
              icon: Icons.format_quote,
              label: 'Citations',
              value: journal.citedByCount.toString(),
            ),
            if (journal.hIndex != null)
              MetricRow(
                icon: Icons.leaderboard_outlined,
                label: 'H-index',
                value: journal.hIndex.toString(),
              ),
            MetricRow(
              icon: Icons.business_outlined,
              label: 'Publisher',
              value: journal.displayPublisher,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onSelect,
                icon: Icon(isSelected ? Icons.check_circle : Icons.done),
                label: Text(isSelected ? 'Selected' : 'Select'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
