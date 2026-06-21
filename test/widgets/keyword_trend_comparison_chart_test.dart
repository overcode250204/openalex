import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/widgets/keyword/charts/keyword_trend_comparison_chart.dart';

void main() {
  testWidgets(
    'renders one point per selected year and zero-fills missing years',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KeywordTrendComparisonChart(
                fromYear: 2011,
                toYear: 2026,
                onYearRangeChanged: (_, _) async {},
                series: const {
                  'Example': [
                    KeywordTrendPoint(year: 2017, count: 7),
                    KeywordTrendPoint(year: 2026, count: 26),
                  ],
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final spots = chart.data.lineBarsData.single.spots;

      expect(spots, hasLength(16));
      expect(
        spots.map((spot) => spot.x.toInt()),
        orderedEquals(List.generate(16, (i) => 2011 + i)),
      );
      expect(spots.take(6).map((spot) => spot.y), everyElement(0));
      expect(spots[6].y, 7);
      expect(chart.data.minX, 2011);
      expect(chart.data.maxX, 2026);
    },
  );
}
