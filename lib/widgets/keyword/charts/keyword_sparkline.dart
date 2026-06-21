import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class KeywordSparkline extends StatefulWidget {
  final int currentPeriodCount;
  final int previousPeriodCount;
  final double growthRate;

  const KeywordSparkline({
    super.key,
    required this.currentPeriodCount,
    required this.previousPeriodCount,
    required this.growthRate,
  });

  @override
  State<KeywordSparkline> createState() => _KeywordSparklineState();
}

class _KeywordSparklineState extends State<KeywordSparkline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color lineColor;
    if (widget.growthRate >= 10.0) {
      lineColor = Colors.green;
    } else if (widget.growthRate <= -10.0) {
      lineColor = Colors.red.shade400;
    } else {
      lineColor = Colors.blueGrey;
    }

    // Determine synthetic points to draw a curve
    // Since we only have current and previous, we interpolate a few points.
    final prev = widget.previousPeriodCount.toDouble();
    final curr = widget.currentPeriodCount.toDouble();
    
    // We create 3 points: start, middle, end.
    // The middle point adds a slight curve rather than a straight line.
    final minVal = prev < curr ? prev : curr;
    final maxVal = prev > curr ? prev : curr;
    final range = maxVal - minVal;
    
    // Smooth easing
    final mid = prev + (curr - prev) * 0.4; // Slightly front-loaded curve

    final spots = [
      FlSpot(0, prev),
      FlSpot(1, mid),
      FlSpot(2, curr),
    ];
    
    final adjustedMaxY = maxVal + (range == 0 ? 1 : range * 0.1);
    final adjustedMinY = minVal - (range == 0 ? 1 : range * 0.1);

    return SizedBox(
      width: 76,
      height: 32,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return LineChart(
            LineChartData(
              minX: 0,
              maxX: 2,
              minY: adjustedMinY,
              maxY: adjustedMaxY,
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots.map((s) => FlSpot(s.x * _animation.value, s.y)).toList(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: lineColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) => spot.x == 2,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: lineColor,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        lineColor.withValues(alpha: 0.2),
                        lineColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
