import 'package:flutter/material.dart';

import '../../models/journal/journal_source.dart';
import '../../utils/app_keys.dart';
import '../../utils/formatters.dart';

class JournalRankingTile extends StatelessWidget {
  final int rank;
  final JournalSource journal;
  final VoidCallback onTap;

  const JournalRankingTile({
    super.key,
    required this.rank,
    required this.journal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      key: AppKeys.journalItem(journal.displayName),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: colorScheme.primary,
          child: Text(
            '#$rank',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          journal.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${Formatters.formatCompactNumber(journal.worksCount)} publications • '
            '${Formatters.formatCompactNumber(journal.citedByCount)} citations • '
            '${journal.averageCitations.toStringAsFixed(1)} avg',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
