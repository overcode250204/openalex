import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_overview.dart';
import 'charts/animated_keyword_progress_bar.dart';
import 'keyword_status_chip.dart';

class MostFrequentKeywordsChart extends StatelessWidget {
  final List<KeywordOverview> keywords;
  final ValueChanged<KeywordOverview> onSelected;

  const MostFrequentKeywordsChart({super.key, required this.keywords, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final maxCount = keywords.isEmpty ? 1 : keywords.first.currentPeriodCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Most Frequent Keywords', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Text('Recent publication volume, not all-time works.'),
          const SizedBox(height: 16),
          for (var index = 0; index < (keywords.length > 5 ? 5 : keywords.length); index++) ...[
            InkWell(
              onTap: () => onSelected(keywords[index]),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${index + 1}',
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
                                  keywords[index].name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              KeywordStatusChip(status: keywords[index].status),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatNumber(keywords[index].currentPeriodCount),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (maxCount > 0)
                              Text(
                                '${((keywords[index].currentPeriodCount / maxCount) * 100).toStringAsFixed(1)}%',
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
                      percentage: keywords[index].currentPeriodCount / maxCount,
                    ),
                  ],
                ),
              ),
            ),
            if (index < (keywords.length > 5 ? 4 : keywords.length - 1))
              const Divider(height: 16, thickness: 0.5),
          ],
        ]),
      ),
    );
  }
}
