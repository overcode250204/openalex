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
        child: Center(
          child: Text('No contributing authors data available.'),
        ),
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

    return SizedBox(
      height: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Number of Papers',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount + (maxCount * 0.2), // Add padding on top for the text
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${topEntries[group.x.toInt()].key}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${rod.toY.toInt()} papers',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= topEntries.length) {
                          return const SizedBox.shrink();
                        }
                        
                        final authorName = topEntries[index].key;
                        // Attempt to split name for better fitting
                        final parts = authorName.split(' ');
                        String displayLine1 = '';
                        String displayLine2 = '';
                        
                        if (parts.length >= 2) {
                          displayLine1 = parts[0];
                          displayLine2 = parts.sublist(1).join(' ');
                          if (displayLine2.length > 10) {
                             displayLine2 = '${displayLine2.substring(0, 8)}...';
                          }
                        } else {
                           displayLine1 = authorName;
                        }

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              children: [
                                Text(
                                  displayLine1,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (displayLine2.isNotEmpty)
                                  Text(
                                    displayLine2,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 9,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxCount > 5 ? (maxCount / 5).ceilToDouble() : 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value % 1 != 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
                  horizontalInterval: maxCount > 5 ? (maxCount / 5).ceilToDouble() : 1,
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
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
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
                        color: Colors.purple.shade400,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
