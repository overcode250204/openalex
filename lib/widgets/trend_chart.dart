import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendChart extends StatelessWidget {
  final Map<int, int> data;

  const TrendChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No trend data available.'),
      );
    }

    final entries = data.entries.toList();
    final minYear = entries.first.key.toDouble();
    final maxYear = entries.last.key.toDouble();
    final maxCount = entries
        .map((entry) => entry.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final spots = entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            entry.value.toDouble(),
          ),
        )
        .toList();

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: minYear,
          maxX: maxYear,
          minY: 0,
          maxY: maxCount + 1,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
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
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) {
                    return const SizedBox.shrink();
                  }

                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final year = value.toInt();

                  if (!data.containsKey(year)) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      year.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
