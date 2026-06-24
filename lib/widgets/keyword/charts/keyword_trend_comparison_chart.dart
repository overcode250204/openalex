import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../utils/formatters.dart';
import '../../../models/keyword/keyword_trend_point.dart';
import 'keyword_chart_card.dart';
import 'keyword_chart_empty_state.dart';
import 'keyword_custom_year_range_picker.dart';
import 'keyword_trend_legend_chip.dart';

class KeywordTrendComparisonChart extends StatefulWidget {
  final Map<String, List<KeywordTrendPoint>> series;
  final int fromYear;
  final int toYear;
  final Future<void> Function(int fromYear, int toYear) onYearRangeChanged;

  const KeywordTrendComparisonChart({
    super.key,
    required this.series,
    required this.fromYear,
    required this.toYear,
    required this.onYearRangeChanged,
  });

  @override
  State<KeywordTrendComparisonChart> createState() =>
      _KeywordTrendComparisonChartState();
}

class _KeywordTrendComparisonChartState
    extends State<KeywordTrendComparisonChart> {
  final Set<String> _hiddenSeries = {};

  static const _colors = [
    Color(0xFF2F6FB0), // Primary Blue
    Color(0xFF8E44AD), // Purple
    Color(0xFF16A085), // Teal/Green
  ];

  /// Minimum pixel width per year point so labels never crowd each other.
  static const double _pixelsPerYear = 52.0;

  /// How many pixels to reserve for the Y-axis label column.
  static const double _yAxisReservedSize = 52.0;

  /// Horizontal padding applied by the parent card (left + right).
  static const double _cardHorizontalPadding = 32.0;

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Returns a step so that at most ~8 labels are shown on the X-axis.
  /// Always shows the first and last year by clamping in the title builder.
  int _xLabelInterval(int totalYears) {
    if (totalYears <= 8) return 1;
    if (totalYears <= 16) return 2;
    if (totalYears <= 24) return 3;
    return 5;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── empty: no series ──────────────────────────────────────────────────
    if (widget.series.isEmpty) {
      return const KeywordChartCard(
        title: 'Keyword Trend Comparison',
        subtitle: 'Publication growth over time',
        child: KeywordChartEmptyState(),
      );
    }

    final topKeywords = widget.series.keys.take(3).toList();

    // ── filter to year range ──────────────────────────────────────────────
    final filtered = <String, List<KeywordTrendPoint>>{};
    for (final keyword in topKeywords) {
      final points = widget.series[keyword]!;
      final inRange = points.where(
        (p) => p.year >= widget.fromYear && p.year <= widget.toYear,
      );
      final byYear = {for (final point in inRange) point.year: point.count};
      filtered[keyword] = [
        for (var year = widget.fromYear; year <= widget.toYear; year++)
          KeywordTrendPoint(year: year, count: byYear[year] ?? 0),
      ];
    }

    final allPoints = filtered.values.expand((v) => v).toList();

    // ── empty: no points after filter ────────────────────────────────────
    if (allPoints.isEmpty) {
      return const KeywordChartCard(
        title: 'Keyword Trend Comparison',
        subtitle: 'Publication growth over time',
        child: KeywordChartEmptyState(),
      );
    }

    // ── axis bounds ───────────────────────────────────────────────────────
    final minYear = widget.fromYear;
    final maxYear = widget.toYear;
    final totalYears = maxYear - minYear + 1;

    final adjustedMinYear = minYear == maxYear ? minYear - 1 : minYear;
    final adjustedMaxYear = minYear == maxYear ? maxYear + 1 : maxYear;

    final visiblePoints = filtered.entries
        .where((e) => !_hiddenSeries.contains(e.key))
        .expand((e) => e.value)
        .toList();

    final maxCount = visiblePoints.isNotEmpty
        ? visiblePoints.map((p) => p.count).reduce((a, b) => a > b ? a : b)
        : 1;

    final yInterval = maxCount > 4 ? (maxCount / 4).ceilToDouble() : 1.0;
    final labelStep = _xLabelInterval(totalYears);

    // ── layout sizing ─────────────────────────────────────────────────────
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth =
        screenWidth - _cardHorizontalPadding - _yAxisReservedSize;

    // Dynamic chart width: expand when there are many years.
    final chartWidth = max(availableWidth, totalYears * _pixelsPerYear);
    final needsScroll = chartWidth > availableWidth;

    return KeywordChartCard(
      title: 'Keyword Trend Comparison',
      subtitle: 'Publication growth over time',
      trailing: KeywordCustomYearRangePicker(
        fromYear: widget.fromYear,
        toYear: widget.toYear,
        onChanged: (from, to) {
          unawaited(widget.onYearRangeChanged(from, to));
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── legend chips ───────────────────────────────────────────────
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
                          return; // keep at least one series visible
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

          const SizedBox(height: 16),

          // ── scroll hint ────────────────────────────────────────────────
          if (needsScroll)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swipe,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe horizontally to explore years',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // ── chart area: X-axis and plot scrollable ─────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
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
                        reservedSize: _yAxisReservedSize,
                        interval: yInterval,
                        getTitlesWidget: _buildYLabel,
                      ),
                    ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                // interval=1 so we get every year as a
                                // potential tick; the builder filters which
                                // ones to actually render.
                                interval: 1,
                                getTitlesWidget: (value, meta) =>
                                    _buildXLabel(
                                  value,
                                  meta,
                                  minYear: minYear,
                                  maxYear: maxYear,
                                  labelStep: labelStep,
                                ),
                              ),
                            ),
                          ),
                  lineTouchData: _buildTouchData(topKeywords),
                  lineBarsData: _buildLineBars(
                    topKeywords,
                    filtered,
                    transparent: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── label builders ────────────────────────────────────────────────────────

  Widget _buildYLabel(double value, TitleMeta meta) {
    if (value % 1 != 0) return const SizedBox.shrink();
    if (value == meta.max) return const SizedBox.shrink(); // skip top overflow
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        Formatters.formatCompactAxis(value.toInt()),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildXLabel(
    double value,
    TitleMeta meta, {
    required int minYear,
    required int maxYear,
    required int labelStep,
  }) {
    final year = value.toInt();
    // Hide out-of-range ticks
    if (year < minYear || year > maxYear) return const SizedBox.shrink();

    // Show first year, last year, and every `labelStep` year
    final isFirst = year == minYear;
    final isLast = year == maxYear;
    final isStep = (year - minYear) % labelStep == 0;

    if (!isFirst && !isLast && !isStep) return const SizedBox.shrink();

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        year.toString(),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      ),
    );
  }

  // ── line bars ─────────────────────────────────────────────────────────────

  List<LineChartBarData> _buildLineBars(
    List<String> topKeywords,
    Map<String, List<KeywordTrendPoint>> filtered, {
    required bool transparent,
  }) {
    return List.generate(topKeywords.length, (index) {
      final keyword = topKeywords[index];
      final isVisible = !_hiddenSeries.contains(keyword) && !transparent;
      final color = _colors[index % _colors.length];
      final isPrimary = index == 0;

      return LineChartBarData(
        show: isVisible,
        spots: filtered[keyword]!
            .map((p) => FlSpot(p.year.toDouble(), p.count.toDouble()))
            .toList(),
        isCurved: true,
        curveSmoothness: 0.35,
        color: transparent ? Colors.transparent : color,
        barWidth: isPrimary ? 3.5 : 2.0,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: isPrimary && isVisible && !transparent,
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
    });
  }

  // ── touch / tooltip ───────────────────────────────────────────────────────

  LineTouchData _buildTouchData(List<String> topKeywords) {
    return LineTouchData(
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
        getTooltipColor: (touchedSpot) => Colors.black.withValues(alpha: 0.8),
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
    );
  }
}
