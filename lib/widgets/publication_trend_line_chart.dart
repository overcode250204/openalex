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

    final entries = data.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));

    final minYear = entries.first.key.toDouble();
    final maxYear = entries.last.key.toDouble();

    int maxCountValue = 0;
    for (var entry in entries) {
      if (entry.value > maxCountValue) maxCountValue = entry.value;
    }
    final maxCount = maxCountValue.toDouble();

    final spots = entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
        .toList();

    return SizedBox(
      height: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publications',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 20,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = math.max(
                    constraints.maxWidth,
                    entries.length * 56.0,
                  );

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: chartWidth,
                      child: LineChart(
                        LineChartData(
                          minX: minYear,
                          maxX: maxYear,
                          minY: 0,
                          maxY: maxCount + (maxCount * 0.2),
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
                                reservedSize: 36,
                                interval: maxCount > 5
                                    ? (maxCount / 5).ceilToDouble()
                                    : 1,
                                getTitlesWidget: (value, TitleMeta meta) {
                                  if (value % 1 != 0) {
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
                                reservedSize: 36,
                                interval: 1,
                                getTitlesWidget: (value, TitleMeta meta) {
                                  final year = value.toInt();
                                  if (!data.containsKey(year)) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 10,
                                    child: SizedBox(
                                      width: 48,
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
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((
                                  LineBarSpot touchedSpot,
                                ) {
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
                            handleBuiltInTouches: true,
                          ),
                          showingTooltipIndicators: spots.asMap().entries.map((
                            e,
                          ) {
                            return ShowingTooltipIndicators([
                              LineBarSpot(
                                lineBarsData[0],
                                0,
                                lineBarsData[0].spots[e.key],
                              ),
                            ]);
                          }).toList(),
                          lineBarsData: lineBarsData,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> get lineBarsData => [
    LineChartBarData(
      spots:
          data.entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
              .toList()
            ..sort((a, b) => a.x.compareTo(b.x)),
      isCurved: true,
      color: Colors.blue.shade500,
      barWidth: 2,
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
            Colors.blue.shade500.withValues(alpha: 0.2),
            Colors.blue.shade500.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),
  ];
}
