import 'package:flutter/material.dart';

import '../../models/journal/journal_publication.dart';

class HighestCitedPaperCard extends StatelessWidget {
  final JournalPublication? publication;
  final bool isLoading;
  final VoidCallback? onViewDetail;

  const HighestCitedPaperCard({
    super.key,
    required this.publication,
    required this.isLoading,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : publication == null
            ? const Text('No highest cited paper found.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Highest Cited Paper',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    publication!.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${publication!.displayYear} - '
                    '${publication!.citedByCount} citations',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DOI: ${publication!.displayDoi}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onViewDetail,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View Detail'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
