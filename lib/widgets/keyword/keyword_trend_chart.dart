import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/keyword/keyword_trend_point.dart';
import '../../viewmodels/keyword_analyzer_view_model.dart';
import '../analytics_chart_card.dart';

class KeywordTrendChart extends StatelessWidget {
  final KeywordAnalyzerViewModel viewModel;
  final List<KeywordTrendPoint> trend;

  const KeywordTrendChart({
    super.key,
    required this.viewModel,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsChartCard(
      title: 'Keyword Trend',
      subtitle: 'Number of papers with this keyword by publication year.',
      customDropdown: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: viewModel.selectedFromYear,
            underline: const SizedBox.shrink(),
            items: List.generate(DateTime.now().year - 1990 + 1, (index) {
              final year = 1990 + index;
              return DropdownMenuItem(value: year, child: Text('$year'));
            }),
            onChanged: (value) async {
              if (value == null) return;
              final fromYear = value;
              final toYear = viewModel.selectedToYear;
              await viewModel.updateKeywordTrendYearRange(
                fromYear: fromYear,
                toYear: fromYear > toYear ? fromYear : toYear,
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('to'),
          ),
          DropdownButton<int>(
            value: viewModel.selectedToYear,
            underline: const SizedBox.shrink(),
            items: List.generate(DateTime.now().year - 1990 + 1, (index) {
              final year = 1990 + index;
              return DropdownMenuItem(value: year, child: Text('$year'));
            }),
            onChanged: (value) async {
              if (value == null) return;
              final toYear = value;
              final fromYear = viewModel.selectedFromYear;
              await viewModel.updateKeywordTrendYearRange(
                fromYear: toYear < fromYear ? toYear : fromYear,
                toYear: toYear,
              );
            },
          ),
        ],
      ),
      child: viewModel.isLoadingTrend
          ? const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            )
          : viewModel.hasTrendError
          ? SizedBox(
              height: 280,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load keyword trend.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: viewModel.reloadKeywordTrend,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : trend.isEmpty
          ? const SizedBox(
              height: 280,
              child: Center(child: Text('No keyword trend data available.')),
            )
          : _TrendLineChart(points: trend),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  final List<KeywordTrendPoint> points;

  const _TrendLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('No trend data available.')),
      );
    }

    final maxCount = points
        .map((point) => point.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final minYear = points.first.year.toDouble();
    final maxYear = points.last.year.toDouble();
    final adjustedMinYear = minYear == maxYear ? minYear - 1 : minYear;
    final adjustedMaxYear = minYear == maxYear ? maxYear + 1 : maxYear;
    final yInterval = maxCount > 5 ? (maxCount / 5).ceilToDouble() : 1.0;

    final spots = points
        .map((point) => FlSpot(point.year.toDouble(), point.count.toDouble()))
        .toList();

    return SizedBox(
      height: 280,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 20),
        child: LineChart(
          LineChartData(
            minX: adjustedMinYear,
            maxX: adjustedMaxYear,
            minY: 0,
            maxY: maxCount + (maxCount * 0.2) + 1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
                dashArray: [5, 5],
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
                  reservedSize: 38,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0) return const SizedBox.shrink();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        Formatters.formatCompactAxis(value.toInt()),
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
                  getTitlesWidget: (value, meta) {
                    final year = value.toInt();
                    if (!points.any((point) => point.year == year)) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 10,
                      child: Text(
                        year.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
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
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.x.toInt()}\nPublications: ${spot.y.toInt()}',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF2F6FB0),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2F6FB0).withValues(alpha: 0.2),
                      const Color(0xFF2F6FB0).withValues(alpha: 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
