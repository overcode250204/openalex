import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';

class CitationTrendChart extends StatelessWidget {
  const CitationTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final data = analytics.publicationTrend;

    if (analytics.isLoading) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No publication trend data')),
      );
    }

    final years = data.keys.toList();
    final spots = years.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), data[years[e.key]]!.toDouble());
    }).toList();

    final maxY = data.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Publication Trend by Year',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'All ${_formatCount(data.values.fold(0, (a, b) => a + b))} papers',
                    style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (v, meta) => Text(
                          _formatCount(v.toInt()),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (years.length / 5).ceilToDouble().clamp(
                          1,
                          double.infinity,
                        ),
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= years.length)
                            return const SizedBox();
                          return Text(
                            years[idx].toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final idx = s.x.toInt();
                        final year = idx >= 0 && idx < years.length
                            ? years[idx]
                            : '';
                        return LineTooltipItem(
                          '$year\n${_formatCount(s.y.toInt())} papers',
                          const TextStyle(color: Colors.white, fontSize: 11),
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

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }
}
