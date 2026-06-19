import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_analysis_result.dart';

class KeywordAnalysisSummary extends StatelessWidget {
  final KeywordAnalysisResult result;

  const KeywordAnalysisSummary({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final mostCitedPaper = result.mostCitedPaper;
    final peakYear = result.peakYear;

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: MediaQuery.sizeOf(context).width > 700 ? 1.55 : 1.15,
      children: [
        _SummaryTile(
          title: 'Total Publications',
          value: Formatters.formatNumber(result.totalPublications),
          icon: Icons.article_outlined,
        ),
        _SummaryTile(
          title: 'Peak Year',
          value: peakYear == null ? 'N/A' : '${peakYear.year}',
          subtitle: peakYear == null
              ? null
              : '${Formatters.formatNumber(peakYear.count)} publications',
          icon: Icons.timeline,
        ),
        _SummaryTile(
          title: 'Most Cited Paper Using This Keyword',
          value: mostCitedPaper == null
              ? 'N/A'
              : Formatters.formatNumber(mostCitedPaper.citedByCount),
          subtitle: mostCitedPaper?.title,
          icon: Icons.format_quote,
          tooltip:
              'Sorted by cited_by_count. Citation count means how many other works cite this paper.',
        ),
        _SummaryTile(
          title: 'Top OA Papers Shown',
          value: '${result.openAccessPapers.length}',
          subtitle: 'Top results',
          icon: Icons.lock_open_outlined,
          tooltip: 'Only the top results fetched from OpenAlex are shown here.',
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final String? tooltip;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2F6FB0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (tooltip != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: tooltip!,
                        child: Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
