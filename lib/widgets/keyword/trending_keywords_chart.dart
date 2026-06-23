import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../../models/keyword/keyword_overview.dart';
import 'charts/keyword_chart_card.dart';
import 'charts/keyword_sparkline.dart';
import 'keyword_status_chip.dart';
import 'keyword_top_n_selector.dart';

class TrendingKeywordsChart extends StatelessWidget {
  final List<KeywordOverview> keywords;
  final int selectedTopN;
  final ValueChanged<int> onTopNChanged;
  final ValueChanged<KeywordOverview> onSelected;

  const TrendingKeywordsChart({
    super.key,
    required this.keywords,
    required this.selectedTopN,
    required this.onTopNChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeywords = [...keywords]
      ..sort((a, b) => b.growthRate.compareTo(a.growthRate));
    final visibleKeywords = sortedKeywords.take(selectedTopN).toList();

    return KeywordChartCard(
      title: 'Trending Keywords',
      subtitle: 'Ranked by publication growth versus the previous 12 months.',
      trailing: KeywordTopNSelector(
        key: const Key('trending_top_n_selector'),
        selectedTopN: selectedTopN,
        onChanged: onTopNChanged,
      ),
      child: Column(
        key: const Key('trending_keywords_list'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < visibleKeywords.length; index++)
            _TrendingKeywordRow(
              keyword: visibleKeywords[index],
              rank: index + 1,
              onSelected: onSelected,
            ),
          if (keywords.length < selectedTopN)
            Padding(
              padding: EdgeInsets.only(top: visibleKeywords.isEmpty ? 0 : 8),
              child: Text(
                'Showing ${keywords.length} available keywords.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendingKeywordRow extends StatelessWidget {
  final KeywordOverview keyword;
  final int rank;
  final ValueChanged<KeywordOverview> onSelected;

  const _TrendingKeywordRow({
    required this.keyword,
    required this.rank,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('trending_keyword_${keyword.id}'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      onTap: () => onSelected(keyword),
      leading: SizedBox(
        width: 28,
        child: Text(
          '$rank.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        keyword.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    KeywordStatusChip(status: keyword.status),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    Text(
                      '${Formatters.formatCompactNumber(keyword.previousPeriodCount)} → '
                      '${Formatters.formatCompactNumber(keyword.currentPeriodCount)} pubs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      Formatters.formatGrowthRate(
                        keyword.growthRate,
                        previousCount: keyword.previousPeriodCount,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: keyword.growthRate >= 10
                            ? Colors.green
                            : keyword.growthRate <= -10
                            ? Colors.red.shade400
                            : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          KeywordSparkline(
            currentPeriodCount: keyword.currentPeriodCount,
            previousPeriodCount: keyword.previousPeriodCount,
            growthRate: keyword.growthRate,
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
