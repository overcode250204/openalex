import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_overview.dart';
import 'charts/keyword_sparkline.dart';
import 'keyword_status_chip.dart';

class TrendingKeywordsChart extends StatelessWidget {
  final List<KeywordOverview> keywords;
  final ValueChanged<KeywordOverview> onSelected;

  const TrendingKeywordsChart({
    super.key,
    required this.keywords,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trending Keywords',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Ranked by publication growth versus the previous 12 months.',
            ),
            const SizedBox(height: 12),
            for (final keyword in keywords)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                onTap: () => onSelected(keyword),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              KeywordStatusChip(status: keyword.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${Formatters.formatCompactNumber(keyword.previousPeriodCount)} → ${Formatters.formatCompactNumber(keyword.currentPeriodCount)} pubs',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
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
                    const SizedBox(width: 12),
                    KeywordSparkline(
                      currentPeriodCount: keyword.currentPeriodCount,
                      previousPeriodCount: keyword.previousPeriodCount,
                      growthRate: keyword.growthRate,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
