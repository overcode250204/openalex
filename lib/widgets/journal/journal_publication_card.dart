import 'package:flutter/material.dart';

import '../../models/journal/journal_publication.dart';

class JournalPublicationCard extends StatelessWidget {
  final JournalPublication publication;
  final VoidCallback onViewDetail;

  const JournalPublicationCard({
    super.key,
    required this.publication,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    publication.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _OpenAccessBadge(isOpenAccess: publication.isOpenAccess),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${publication.displayDate} - ${publication.displayJournal}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              'DOI: ${publication.displayDoi}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.format_quote, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  '${publication.citedByCount} citations',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View Detail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenAccessBadge extends StatelessWidget {
  final bool isOpenAccess;

  const _OpenAccessBadge({required this.isOpenAccess});

  @override
  Widget build(BuildContext context) {
    final color = isOpenAccess ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpenAccess ? 'Open Access' : 'Closed',
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
