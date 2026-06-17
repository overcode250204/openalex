import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TopResearchJournalsDonutChart extends StatefulWidget {
  final Map<String, int> journalsData;

  const TopResearchJournalsDonutChart({
    super.key,
    required this.journalsData,
  });

  @override
  State<TopResearchJournalsDonutChart> createState() => _TopResearchJournalsDonutChartState();
}

class _TopResearchJournalsDonutChartState extends State<TopResearchJournalsDonutChart> {
  int touchedIndex = -1;

  final List<Color> chartColors = [
    Colors.blue.shade500,
    Colors.green.shade500,
    Colors.purple.shade400,
    Colors.orange.shade500,
    Colors.red.shade400,
    Colors.pink.shade400,
    Colors.grey.shade400,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.journalsData.isEmpty) {
      return const SizedBox(
        height: 330,
        child: Center(
          child: Text('No research journals data available.'),
        ),
      );
    }

    // Process data: Top 6 and Others
    final entries = widget.journalsData.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, int>> processedEntries = [];
    int otherCount = 0;

    for (int i = 0; i < entries.length; i++) {
      if (i < 6) {
        processedEntries.add(entries[i]);
      } else {
        otherCount += entries[i].value;
      }
    }

    if (otherCount > 0) {
      processedEntries.add(MapEntry('Others', otherCount));
    }

    final totalPapers = processedEntries.fold(0, (sum, entry) => sum + entry.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 300;
        
        final chartWidget = SizedBox(
          height: 200,
          width: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(processedEntries.length, (i) {
                    final isTouched = i == touchedIndex;
                    final fontSize = isTouched ? 14.0 : 12.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    final entry = processedEntries[i];
                    final percentage = (entry.value / totalPapers) * 100;
                    
                    return PieChartSectionData(
                      color: chartColors[i % chartColors.length],
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.journalsData.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Journals',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final legendWidget = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(processedEntries.length, (index) {
            final entry = processedEntries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chartColors[index % chartColors.length],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value} ${entry.value == 1 ? 'paper' : 'papers'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
        );

        if (isSmallScreen) {
          return Column(
            children: [
              chartWidget,
              const SizedBox(height: 24),
              legendWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            chartWidget,
            const SizedBox(width: 16),
            Expanded(child: legendWidget),
          ],
        );
      },
    );
  }
}
