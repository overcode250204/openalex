import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/keyword/keyword_overview.dart';
import 'keyword_status_chip.dart';

class MostFrequentKeywordsChart extends StatelessWidget {
  final List<KeywordOverview> keywords;
  final ValueChanged<KeywordOverview> onSelected;

  const MostFrequentKeywordsChart({super.key, required this.keywords, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final maxCount = keywords.isEmpty ? 1 : keywords.first.currentPeriodCount;
    final format = NumberFormat.decimalPattern();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Most Frequent Keywords', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Text('Recent publication volume, not all-time works.'),
          const SizedBox(height: 16),
          for (var index = 0; index < keywords.length; index++) ...[
            InkWell(
              onTap: () => onSelected(keywords[index]),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(children: [
                  Row(children: [
                    SizedBox(width: 28, child: Text('#${index + 1}')),
                    Expanded(child: Text(keywords[index].name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    KeywordStatusChip(status: keywords[index].status),
                    const SizedBox(width: 10),
                    Text(format.format(keywords[index].currentPeriodCount)),
                  ]),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: keywords[index].currentPeriodCount / maxCount),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
