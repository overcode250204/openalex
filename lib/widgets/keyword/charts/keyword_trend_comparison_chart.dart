import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/keyword/keyword_trend_point.dart';
import 'keyword_chart_card.dart';
import 'keyword_chart_empty_state.dart';
import 'keyword_custom_year_range_picker.dart';
import 'keyword_trend_legend_chip.dart';

class KeywordTrendComparisonChart extends StatefulWidget {
  final Map<String, List<KeywordTrendPoint>> series;

  const KeywordTrendComparisonChart({super.key, required this.series});

  @override
  State<KeywordTrendComparisonChart> createState() =>
      _KeywordTrendComparisonChartState();
}

class _KeywordTrendComparisonChartState
    extends State<KeywordTrendComparisonChart> {
  int _fromYear = DateTime.now().year - 10;
  int _toYear = DateTime.now().year;
  final Set<String> _hiddenSeries = {};

  static const _colors = [
    Color(0xFF2F6FB0), // Primary Blue
    Color(0xFF8E44AD), // Purple
    Color(0xFF16A085), // Teal/Green
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.series.isEmpty) {
      return const KeywordChartCard(
        title: 'Keyword Trend Comparison',
        subtitle: 'Publication growth over time',
        child: KeywordChartEmptyState(),
      );
    }

    final topKeywords = widget.series.keys.take(3).toList();

    // Filter by date range
    final filtered = <String, List<KeywordTrendPoint>>{};
    for (final keyword in topKeywords) {
      final points = widget.series[keyword]!;
      filtered[keyword] = points
          .where((p) => p.year >= _fromYear && p.year <= _toYear)
          .toList();
    }

    final allPoints = filtered.values.expand((v) => v).toList();
    if (allPoints.isEmpty) {
      return const KeywordChartCard(
        title: 'Keyword Trend Comparison',
        subtitle: 'Publication growth over time',
        child: KeywordChartEmptyState(),
      );
    }

    // Use user-selected range for x-axis bounds, not the actual data min/max
    final minYear = _fromYear;
    final maxYear = _toYear;

    // Only calculate max count based on visible series
    final visiblePoints = filtered.entries
        .where((e) => !_hiddenSeries.contains(e.key))
        .expand((e) => e.value)
        .toList();

    final maxCount = visiblePoints.isNotEmpty
        ? visiblePoints.map((p) => p.count).reduce((a, b) => a > b ? a : b)
        : 1;

    final adjustedMinYear = minYear == maxYear ? minYear - 1 : minYear;
    final adjustedMaxYear = minYear == maxYear ? maxYear + 1 : maxYear;
    final xInterval = (adjustedMaxYear - adjustedMinYear) > 10 ? 2.0 : 1.0;

    final yInterval = maxCount > 4 ? (maxCount / 4).ceilToDouble() : 1.0;

    return KeywordChartCard(
      title: 'Keyword Trend Comparison',
      subtitle: 'Publication growth over time',
      trailing: KeywordCustomYearRangePicker(
        fromYear: _fromYear,
        toYear: _toYear,
        onChanged: (from, to) {
          setState(() {
            _fromYear = from;
            _toYear = to;
          });
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(topKeywords.length, (index) {
                final keyword = topKeywords[index];
                final isVisible = !_hiddenSeries.contains(keyword);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: KeywordTrendLegendChip(
                    label: keyword,
                    color: _colors[index % _colors.length],
                    isVisible: isVisible,
                    onToggle: () {
                      setState(() {
                        if (isVisible &&
                            topKeywords.length - _hiddenSeries.length <= 1) {
                          // Prevent hiding the last series
                          return;
                        }
                        if (isVisible) {
                          _hiddenSeries.add(keyword);
                        } else {
                          _hiddenSeries.remove(keyword);
                        }
                      });
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              LineChartData(
                minX: adjustedMinYear.toDouble(),
                maxX: adjustedMaxYear.toDouble(),
                minY: 0,
                maxY: maxCount + (maxCount * 0.15) + 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
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
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0 || value == 0) {
                          if (value == 0) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            Formatters.formatCompactAxis(value.toInt()),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        final year = value.toInt();
                        if (year < minYear || year > maxYear) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((spotIndex) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 2,
                              dashArray: [4, 4],
                            ),
                            FlDotData(
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: barData.color ?? Colors.blue,
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        Colors.black.withValues(alpha: 0.8),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final keyword = topKeywords[spot.barIndex];
                        if (_hiddenSeries.contains(keyword)) return null;

                        final color = _colors[spot.barIndex % _colors.length];
                        return LineTooltipItem(
                          '',
                          const TextStyle(),
                          children: [
                            TextSpan(
                              text: '${spot.x.toInt()}\n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '$keyword\n',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${Formatters.formatCompactAxis(spot.y.toInt())} works',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: List.generate(topKeywords.length, (index) {
                  final keyword = topKeywords[index];
                  final isVisible = !_hiddenSeries.contains(keyword);
                  final color = _colors[index % _colors.length];
                  final isPrimary = index == 0;

                  return LineChartBarData(
                    show: isVisible,
                    spots: filtered[keyword]!
                        .map(
                          (p) => FlSpot(p.year.toDouble(), p.count.toDouble()),
                        )
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: isPrimary ? 3.5 : 2.0,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: isPrimary && isVisible,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
