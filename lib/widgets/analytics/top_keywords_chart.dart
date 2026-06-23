import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/analytics_view_model.dart';

class TopKeywordsChart extends StatelessWidget {
  const TopKeywordsChart({super.key});

  static const double _barWidth = 28;
  static const double _itemWidth = 72;
  static const double _chartHeight = 180;

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsViewModel>();
    final data = analytics.topKeywords;

    if (analytics.isLoading) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = data.entries.toList();
    final maxVal = entries.first.value.toDouble();
    final chartWidth = entries.length * _itemWidth;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Top Research Keywords',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(Icons.swipe, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'swipe',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _chartHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal * 1.3,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          fitInsideVertically: true,
                          fitInsideHorizontally: true,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                              BarTooltipItem(
                                '${entries[group.x].key}\n${_fmt(rod.toY.toInt())} papers',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, meta) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= entries.length) {
                                return const SizedBox();
                              }
                              final label = entries[idx].key;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label.length > 9
                                      ? '${label.substring(0, 8)}…'
                                      : label,
                                  style: const TextStyle(fontSize: 9),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) => Text(
                              _fmt(v.toInt()),
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(drawVerticalLine: false),
                      barGroups: entries.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value.toDouble(),
                              color: Colors.green,
                              width: _barWidth,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(0)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }
}
