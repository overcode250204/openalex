import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../utils/formatters.dart';
import '../../../models/keyword/keyword_trend_point.dart';
import '../../../viewmodels/keyword_analyzer_view_model.dart';
import 'keyword_chart_card.dart';
import 'keyword_chart_empty_state.dart';
import 'keyword_chart_error_state.dart';
import 'keyword_chart_skeleton.dart';
import 'keyword_custom_year_range_picker.dart';

class KeywordPublicationTrendChart extends StatelessWidget {
  final KeywordAnalyzerViewModel viewModel;
  final List<KeywordTrendPoint> trend;

  const KeywordPublicationTrendChart({
    super.key,
    required this.viewModel,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoadingTrend) {
      return const KeywordChartCard(
        title: 'Publication Trend',
        subtitle: 'Research activity over time',
        child: KeywordChartSkeleton(),
      );
    }

    if (viewModel.hasTrendError) {
      return KeywordChartCard(
        title: 'Publication Trend',
        subtitle: 'Research activity over time',
        child: KeywordChartErrorState(onRetry: viewModel.reloadKeywordTrend),
      );
    }

    if (trend.isEmpty) {
      return const KeywordChartCard(
        title: 'Publication Trend',
        subtitle: 'Research activity over time',
        child: KeywordChartEmptyState(),
      );
    }

    return KeywordChartCard(
      title: 'Publication Trend',
      subtitle: 'Research activity over time',
      trailing: KeywordCustomYearRangePicker(
        fromYear: viewModel.selectedFromYear,
        toYear: viewModel.selectedToYear,
        onChanged: (fromYear, toYear) {
          viewModel.updateKeywordTrendYearRange(
            fromYear: fromYear,
            toYear: toYear,
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsightRow(trend: trend),
          const SizedBox(height: 24),
          _TrendLineChart(points: trend),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final List<KeywordTrendPoint> trend;

  const _InsightRow({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final peakPoint = trend.reduce((a, b) => a.count > b.count ? a : b);

    // Calculate simple trend status based on last two years if available
    String status = 'Stable';
    Color statusColor = Colors.grey;
    if (trend.length >= 2) {
      final last = trend.last.count;
      final prev = trend[trend.length - 2].count;
      if (last > prev * 1.05) {
        status = 'Growing';
        statusColor = Colors.green;
      } else if (last < prev * 0.95) {
        status = 'Declining';
        statusColor = Colors.orange;
      }
    }

    return Row(
      children: [
        _MetricChip(
          label: 'Peak Year',
          value: peakPoint.year.toString(),
          icon: Icons.emoji_events,
          color: Colors.amber.shade700,
        ),
        const SizedBox(width: 12),
        _MetricChip(
          label: 'Peak Pubs',
          value: Formatters.formatCompactNumber(peakPoint.count),
          icon: Icons.auto_graph,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        _MetricChip(
          label: 'Status',
          value: status,
          icon: status == 'Growing'
              ? Icons.trending_up
              : status == 'Declining'
              ? Icons.trending_down
              : Icons.trending_flat,
          color: statusColor,
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  final List<KeywordTrendPoint> points;

  const _TrendLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxCount = points
        .map((p) => p.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final minYear = points.first.year.toDouble();
    final maxYear = points.last.year.toDouble();
    final adjustedMinYear = minYear == maxYear ? minYear - 1 : minYear;
    final adjustedMaxYear = minYear == maxYear ? maxYear + 1 : maxYear;

    final yInterval = maxCount > 4 ? (maxCount / 4).ceilToDouble() : 1.0;
    final xInterval = (adjustedMaxYear - adjustedMinYear) > 10 ? 2.0 : 1.0;

    final spots = points
        .map((p) => FlSpot(p.year.toDouble(), p.count.toDouble()))
        .toList();
    final peakSpot = spots.reduce((a, b) => a.y > b.y ? a : b);

    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 250,
      child: LineChart(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        LineChartData(
          minX: adjustedMinYear,
          maxX: adjustedMaxYear,
          minY: 0,
          maxY:
              maxCount +
              (maxCount * 0.25) +
              1, // extra space for peak annotation
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
            getTouchedSpotIndicator: (barData, spotIndexes) {
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
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: color,
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
                  // Calculate YoY change if possible
                  String yoyChange = '';
                  if (spot.spotIndex > 0) {
                    final prev = points[spot.spotIndex - 1].count;
                    final current = spot.y;
                    if (prev > 0) {
                      final change = ((current - prev) / prev) * 100;
                      yoyChange =
                          '\n${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% YoY';
                    }
                  }

                  return LineTooltipItem(
                    '',
                    const TextStyle(),
                    children: [
                      TextSpan(
                        text: '${spot.x.toInt()}\n',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${Formatters.formatNumber(spot.y.toInt())} publications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      if (yoyChange.isNotEmpty)
                        TextSpan(
                          text: yoyChange,
                          style: TextStyle(
                            color: yoyChange.contains('+')
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          showingTooltipIndicators: [
            // Always show the peak point tooltip as an annotation bubble
            ShowingTooltipIndicators([
              LineBarSpot(LineChartBarData(spots: spots), 0, peakSpot),
            ]),
          ],
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) {
                  // Show dot only for the last point (latest year) and peak point
                  return spot.x == maxYear || spot.x == peakSpot.x;
                },
                getDotPainter: (spot, percent, barData, index) {
                  if (spot.x == peakSpot.x) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.amber.shade700,
                    );
                  }
                  // Animated glowing point for latest year would require a StatefulWidget
                  // For simplicity in fl_chart, we use a distinct style
                  return FlDotCirclePainter(
                    radius: 5,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
