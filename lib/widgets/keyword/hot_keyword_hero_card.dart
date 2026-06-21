import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_overview.dart';
import 'keyword_status_chip.dart';

class HotKeywordHeroCard extends StatelessWidget {
  final KeywordOverview keyword;
  final VoidCallback onViewDetail;
  final VoidCallback onShowCalculation;

  const HotKeywordHeroCard({
    super.key,
    required this.keyword,
    required this.onViewDetail,
    required this.onShowCalculation,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern();
    final growth = Formatters.formatGrowthRate(
      keyword.growthRate,
      previousCount: keyword.previousPeriodCount,
    );
    return Card(
      color: const Color(0xFFEAF3FF),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Current Hot Keyword',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'How Hot Score Is Calculated',
                  onPressed: onShowCalculation,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  keyword.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                KeywordStatusChip(status: keyword.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Recent publications: ${format.format(keyword.currentPeriodCount)}',
            ),
            Text(
              'Previous period: ${format.format(keyword.previousPeriodCount)}',
            ),
            Text(
              'Growth: $growth',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            Text(_summary(keyword.growthRate)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onViewDetail,
              child: const Text('View Detail'),
            ),
          ],
        ),
      ),
    );
  }

  String _summary(double growth) {
    if (growth >= 100) return 'Strong upward publication growth';
    if (growth >= 30) return 'Emerging research activity';
    if (growth <= -10) return 'Publication activity is declining';
    return 'Publication activity is stable';
  }
}
