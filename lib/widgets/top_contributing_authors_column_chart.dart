import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TopContributingAuthorsColumnChart extends StatelessWidget {
  final Map<String, int> authorsData;

  const TopContributingAuthorsColumnChart({
    super.key,
    required this.authorsData,
  });

  @override
  Widget build(BuildContext context) {
    if (authorsData.isEmpty) {
      return const SizedBox(
        height: 230,
        child: Center(child: Text('No contributing authors data available.')),
      );
    }

    // Process data: Top 10
    final entries = authorsData.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(10).toList();

    int maxCountValue = 0;
    for (var entry in topEntries) {
      if (entry.value > maxCountValue) maxCountValue = entry.value;
    }
    final maxCount = maxCountValue.toDouble();
    final maxY = maxCount + (maxCount * 0.1).ceilToDouble() + 1;
    final yInterval = maxCount > 5 ? (maxCount / 5).ceilToDouble() : 1.0;

    return SizedBox(
      height: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Number of Papers',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = math.max(
                  constraints.maxWidth,
                  topEntries.length * 72.0,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: chartWidth,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) =>
                                const Color(0xFF546A76),
                            tooltipRoundedRadius: 6,
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final index = group.x.toInt();

                              if (index < 0 || index >= topEntries.length) {
                                return null;
                              }

                              final authorName = topEntries[index].key;

                              return BarTooltipItem(
                                '$authorName\n${rod.toY.toInt()} papers',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 62,
                              getTitlesWidget: (
                                double value,
                                TitleMeta meta,
                              ) {
                                final index = value.toInt();
                                if (index < 0 || index >= topEntries.length) {
                                  return const SizedBox.shrink();
                                }

                                final authorName = topEntries[index].key;
                                final label = _formatAuthorLabel(authorName);

                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: SizedBox(
                                    width: 68,
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: yInterval,
                              getTitlesWidget: (
                                double value,
                                TitleMeta meta,
                              ) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    _formatAxisValue(value.toInt()),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
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
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: yInterval,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            left: BorderSide.none,
                            right: BorderSide.none,
                            top: BorderSide.none,
                          ),
                        ),
                        barGroups: topEntries.asMap().entries.map((e) {
                          final index = e.key;
                          final count = e.value.value.toDouble();
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: count,
                                color: const Color(0xFF9C27B0),
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAxisValue(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toString();
  }

  static String _formatAuthorLabel(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.length <= 2) {
      return name;
    }

    final firstLine = parts.take(parts.length - 1).join(' ');
    final lastLine = parts.last;

    String shortFirstLine = firstLine;
    if (shortFirstLine.length > 10) {
      shortFirstLine = '${shortFirstLine.substring(0, 10)}...';
    }

    return '$shortFirstLine\n$lastLine';
  }
}
