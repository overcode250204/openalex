import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/keyword/keyword_overview.dart';
import 'keyword_status_chip.dart';

class TrendingKeywordsChart extends StatelessWidget {
  final List<KeywordOverview> keywords;
  final ValueChanged<KeywordOverview> onSelected;

  const TrendingKeywordsChart({super.key, required this.keywords, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Trending Keywords', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Text('Ranked by publication growth versus the previous 12 months.'),
          const SizedBox(height: 12),
          for (final keyword in keywords)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => onSelected(keyword),
              leading: const Icon(Icons.trending_up, color: Colors.green),
              title: Text(keyword.name),
              subtitle: Text('${format.format(keyword.previousPeriodCount)} → ${format.format(keyword.currentPeriodCount)} publications'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${keyword.growthRate >= 0 ? '+' : ''}${keyword.growthRate.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                KeywordStatusChip(status: keyword.status),
              ]),
            ),
        ]),
      ),
    );
  }
}
