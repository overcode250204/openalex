import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_analysis_paper.dart';

class KeywordPaperListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<KeywordAnalysisPaper> papers;
  final ValueChanged<KeywordAnalysisPaper>? onPaperTap;
  final bool showLinks;
  final bool showKeywordScore;

  const KeywordPaperListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.papers,
    this.onPaperTap,
    this.showLinks = false,
    this.showKeywordScore = false,
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (papers.isEmpty)
            SizedBox(height: 120, child: Center(child: Text(emptyMessage)))
          else
            ...papers.asMap().entries.map((entry) {
              final index = entry.key;
              final paper = entry.value;
              return Column(
                children: [
                  _PaperRow(
                    paper: paper,
                    onTap: onPaperTap == null ? null : () => onPaperTap!(paper),
                    showLinks: showLinks,
                    showKeywordScore: showKeywordScore,
                  ),
                  if (index < papers.length - 1)
                    Divider(height: 1, color: Colors.grey.shade200),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _PaperRow extends StatelessWidget {
  final KeywordAnalysisPaper paper;
  final VoidCallback? onTap;
  final bool showLinks;
  final bool showKeywordScore;

  const _PaperRow({
    required this.paper,
    required this.onTap,
    required this.showLinks,
    required this.showKeywordScore,
  });

  @override
  Widget build(BuildContext context) {
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
                    paper.title.trim().isEmpty ? 'Untitled paper' : paper.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paper.displayYearAndSource,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (showKeywordScore && paper.keywordScore > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Keyword relevance: ${paper.keywordScore.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
            const SizedBox(width: 8),
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 84),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatNumber(paper.citedByCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F6FB0),
                      ),
                    ),
                    Text(
                      'citations',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
