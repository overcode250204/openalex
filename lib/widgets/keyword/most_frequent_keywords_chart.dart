import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_overview.dart';
import 'charts/animated_keyword_progress_bar.dart';
import 'charts/keyword_chart_card.dart';
import 'keyword_status_chip.dart';
import 'keyword_top_n_selector.dart';

class MostFrequentKeywordsChart extends StatelessWidget {
  final List<KeywordOverview> keywords;
  final int selectedTopN;
  final ValueChanged<int> onTopNChanged;
  final ValueChanged<KeywordOverview> onSelected;

  const MostFrequentKeywordsChart({
    super.key,
    required this.keywords,
    required this.selectedTopN,
    required this.onTopNChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeywords = [...keywords]
      ..sort((a, b) => b.currentPeriodCount.compareTo(a.currentPeriodCount));
    final visibleKeywords = sortedKeywords.take(selectedTopN).toList();
    final maxCount = visibleKeywords.isEmpty
        ? 1
        : visibleKeywords.first.currentPeriodCount;

    return KeywordChartCard(
      title: 'Most Frequent Keywords',
      subtitle: 'Recent publication volume, not all-time works.',
      trailing: KeywordTopNSelector(
        key: const Key('most_frequent_top_n_selector'),
        selectedTopN: selectedTopN,
        onChanged: onTopNChanged,
      ),
      child: Column(
        key: const Key('most_frequent_keywords_list'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < visibleKeywords.length; index++) ...[
            _FrequentKeywordRow(
              keyword: visibleKeywords[index],
              rank: index + 1,
              maxCount: maxCount,
              onSelected: onSelected,
            ),
            if (index < visibleKeywords.length - 1)
              const Divider(height: 16, thickness: 0.5),
          ],
          if (keywords.length < selectedTopN)
            Padding(
              padding: EdgeInsets.only(top: visibleKeywords.isEmpty ? 0 : 12),
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

class _FrequentKeywordRow extends StatelessWidget {
  final KeywordOverview keyword;
  final int rank;
  final int maxCount;
  final ValueChanged<KeywordOverview> onSelected;

  const _FrequentKeywordRow({
    required this.keyword,
    required this.rank,
    required this.maxCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('most_frequent_keyword_${keyword.id}'),
      onTap: () => onSelected(keyword),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
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
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatNumber(keyword.currentPeriodCount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (maxCount > 0)
                      Text(
                        '${((keyword.currentPeriodCount / maxCount) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedKeywordProgressBar(
              percentage: maxCount > 0
                  ? keyword.currentPeriodCount / maxCount
                  : 0,
            ),
          ],
        ),
      ),
    );
  }
}
