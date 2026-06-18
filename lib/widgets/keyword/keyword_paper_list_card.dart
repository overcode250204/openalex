import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_analysis_paper.dart';

class KeywordPaperListCard extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<KeywordAnalysisPaper> papers;
  final ValueChanged<KeywordAnalysisPaper>? onPaperTap;
  final bool showDate;
  final bool showLinks;

  const KeywordPaperListCard({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.papers,
    this.onPaperTap,
    this.showDate = false,
    this.showLinks = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (papers.isEmpty)
            SizedBox(height: 120, child: Center(child: Text(emptyMessage)))
          else
            ...papers.map(
              (paper) => _PaperRow(
                paper: paper,
                onTap: onPaperTap == null ? null : () => onPaperTap!(paper),
                showDate: showDate,
                showLinks: showLinks,
              ),
            ),
        ],
      ),
    );
  }
}

class _PaperRow extends StatelessWidget {
  final KeywordAnalysisPaper paper;
  final VoidCallback? onTap;
  final bool showDate;
  final bool showLinks;

  const _PaperRow({
    required this.paper,
    required this.onTap,
    required this.showDate,
    required this.showLinks,
  });

  @override
  Widget build(BuildContext context) {
    final meta = showDate
        ? '${paper.displayDate} - ${paper.displaySource}'
        : paper.displayYearAndSource;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (showLinks) ...[
                    const SizedBox(height: 4),
                    Text(
                      paper.pdfUrl ??
                          paper.landingPageUrl ??
                          paper.doi ??
                          'No link available',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCitation(paper.citedByCount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F6FB0),
                  ),
                ),
                Text(
                  'citations',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
