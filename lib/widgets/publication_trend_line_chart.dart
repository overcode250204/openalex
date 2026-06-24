import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class PublicationTrendLineChart extends StatelessWidget {
  final Map<int, int> data;

  const PublicationTrendLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('No trend data available.')),
      );
    }

    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final minYear = entries.first.key.toDouble();
    final maxYear = entries.last.key.toDouble();

    final maxCountValue = entries.fold<int>(
      0,
      (maxValue, entry) => math.max(maxValue, entry.value),
    );

    final maxCount = maxCountValue.toDouble();
    final chartMaxY = maxCount <= 0 ? 1.0 : maxCount + (maxCount * 0.2);

    final spots = entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
        .toList();

    final lineData = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.blue.shade500,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Colors.blue.shade500,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade500.withValues(alpha: 0.22),
            Colors.blue.shade500.withValues(alpha: 0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );

    return SizedBox(
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publications',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Mỗi năm có tối thiểu 58px để label không bị đè.
                final chartWidth = math.max(
                  constraints.maxWidth,
                  entries.length * 58.0,
                );

                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: chartWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 8,
                          top: 8,
                          bottom: 8,
                        ),
                        child: LineChart(
                          LineChartData(
                            minX: minYear,
                            maxX: maxYear,
                            minY: 0,
                            maxY: chartMaxY,
                            lineBarsData: [lineData],
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxCount > 5
                                  ? (maxCount / 5).ceilToDouble()
                                  : 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              },
                            ),
                            borderData: FlBorderData(show: false),
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
                                  interval: maxCount > 5
                                      ? (maxCount / 5).ceilToDouble()
                                      : 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value < 0 || value % 1 != 0) {
                                      return const SizedBox.shrink();
                                    }

                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        Formatters.formatCompactAxis(
                                          value.toInt(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 38,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final year = value.toInt();

                                    if (!data.containsKey(year)) {
                                      return const SizedBox.shrink();
                                    }

                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 10,
                                      child: SizedBox(
                                        width: 52,
                                        child: Text(
                                          year.toString(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    final year = touchedSpot.x.toInt();
                                    final publications = touchedSpot.y.toInt();

                                    return LineTooltipItem(
                                      '$year\n',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Publications: $publications',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Swipe horizontally to view all years',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
