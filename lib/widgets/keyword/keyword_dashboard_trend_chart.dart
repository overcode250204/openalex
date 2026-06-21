import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_trend_point.dart';

enum KeywordTrendRange { fiveYears, tenYears, all }

class KeywordDashboardTrendChart extends StatefulWidget {
  final Map<String, List<KeywordTrendPoint>> series;

  const KeywordDashboardTrendChart({super.key, required this.series});

  @override
  State<KeywordDashboardTrendChart> createState() =>
      _KeywordDashboardTrendChartState();
}

class _KeywordDashboardTrendChartState
    extends State<KeywordDashboardTrendChart> {
  KeywordTrendRange _range = KeywordTrendRange.tenYears;
  static const _colors = [
    Color(0xFF2F6FB0),
    Color(0xFFE67E22),
    Color(0xFF16A085),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = <String, List<KeywordTrendPoint>>{};
    for (final entry in widget.series.entries.take(3)) {
      final limit = switch (_range) {
        KeywordTrendRange.fiveYears => 5,
        KeywordTrendRange.tenYears => 10,
        KeywordTrendRange.all => entry.value.length,
      };
      filtered[entry.key] = KeywordTrendPoint.latestPoints(
        entry.value,
        limit: limit,
      );
    }
    final points = filtered.values.expand((value) => value).toList();
    if (points.isEmpty) return const SizedBox.shrink();
    final minYear = points.map((p) => p.year).reduce((a, b) => a < b ? a : b);
    final maxYear = points.map((p) => p.year).reduce((a, b) => a > b ? a : b);
    final maxCount = points.map((p) => p.count).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Keyword Trend Comparison',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DropdownButton<KeywordTrendRange>(
                  value: _range,
                  items: const [
                    DropdownMenuItem(
                      value: KeywordTrendRange.fiveYears,
                      child: Text('Last 5 years'),
                    ),
                    DropdownMenuItem(
                      value: KeywordTrendRange.tenYears,
                      child: Text('Last 10 years'),
                    ),
                    DropdownMenuItem(
                      value: KeywordTrendRange.all,
                      child: Text('All available years'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _range = value ?? _range),
                ),
              ],
            ),
            Wrap(
              spacing: 16,
              children: [
                for (var i = 0; i < filtered.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 3, color: _colors[i]),
                      const SizedBox(width: 5),
                      Text(filtered.keys.elementAt(i)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: minYear.toDouble(),
                  maxX: (maxYear == minYear ? maxYear + 1 : maxYear).toDouble(),
                  minY: 0,
                  maxY: maxCount * 1.15 + 1,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => Text(
                          Formatters.formatCompactAxis(value.toInt()),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final name = filtered.keys.elementAt(spot.barIndex);
                        return LineTooltipItem(
                          '$name\n${spot.x.toInt()}: ${spot.y.toInt()} publications',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    for (var i = 0; i < filtered.length; i++)
                      LineChartBarData(
                        spots: filtered.values
                            .elementAt(i)
                            .map(
                              (p) =>
                                  FlSpot(p.year.toDouble(), p.count.toDouble()),
                            )
                            .toList(),
                        color: _colors[i],
                        barWidth: 3,
                        isCurved: true,
                        dotData: FlDotData(show: false),
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
