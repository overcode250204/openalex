import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';

class AuthorImpactChart extends StatelessWidget {
  const AuthorImpactChart({super.key});

  @override
  Widget build(BuildContext context) {
    final authors = context.watch<AnalyticsProvider>().authorImpact;

    if (authors.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No author data')),
      );
    }

    final spots = authors.map((a) {
      return ScatterSpot(
        a.paperCount.toDouble(),
        a.totalCitations.toDouble(),
        dotPainter: FlDotCirclePainter(
          radius: 5,
          color: Colors.purple.withValues(alpha: 0.7),
        ),
      );
    }).toList();

    final maxX = authors.map((a) => a.paperCount).reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = authors.map((a) => a.totalCitations).reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author Impact (Papers vs Citations)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Each dot = one author',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ScatterChart(
                ScatterChartData(
                  minX: 0,
                  maxX: maxX * 1.1,
                  minY: 0,
                  maxY: maxY * 1.1,
                  scatterSpots: spots,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('Total Citations', style: TextStyle(fontSize: 10)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (v, _) => Text(
                          v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Paper Count', style: TextStyle(fontSize: 10)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  scatterTouchData: ScatterTouchData(
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipItems: (spot) {
                        final match = authors.where((a) =>
                            a.paperCount.toDouble() == spot.x &&
                            a.totalCitations.toDouble() == spot.y);
                        final name = match.isNotEmpty ? match.first.name : '';
                        return ScatterTooltipItem(
                          '${name.length > 20 ? '${name.substring(0, 18)}…' : name}\n'
                          '${spot.x.toInt()} papers · ${spot.y.toInt()} citations',
                          textStyle: const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
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
}
