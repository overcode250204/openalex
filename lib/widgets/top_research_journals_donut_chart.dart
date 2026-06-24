import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TopResearchJournalsDonutChart extends StatefulWidget {
  final Map<String, int> journalsData;

  const TopResearchJournalsDonutChart({super.key, required this.journalsData});

  @override
  State<TopResearchJournalsDonutChart> createState() =>
      _TopResearchJournalsDonutChartState();
}

class _TopResearchJournalsDonutChartState
    extends State<TopResearchJournalsDonutChart> {
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
        child: Center(child: Text('No research journals data available.')),
      );
    }

    final donutEntries = widget.journalsData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalPapers = donutEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 520;
        final chartSize = useVerticalLayout
            ? constraints.maxWidth.clamp(180.0, 220.0).toDouble()
            : 200.0;

        final chartWidget = SizedBox(
          height: chartSize,
          width: chartSize,
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
                        touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(donutEntries.length, (i) {
                    final isTouched = i == touchedIndex;
                    final fontSize = isTouched ? 14.0 : 12.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    final entry = donutEntries[i];
                    final percentage = totalPapers > 0
                        ? (entry.value / totalPapers) * 100
                        : 0.0;
                    final color = entry.key == 'Others'
                        ? Colors.grey.shade300
                        : chartColors[i % chartColors.length];

                    return PieChartSectionData(
                      color: color,
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
                    '${donutEntries.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Journals',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        );

        final legendWidget = ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(donutEntries.length, (index) {
              final entry = donutEntries[index];
              final color = chartColors[index % chartColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: useVerticalLayout ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: Text(
                        '${entry.value} ${entry.value == 1 ? 'paper' : 'papers'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );

        if (useVerticalLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: chartWidget),
              const SizedBox(height: 20),
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
