import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/widgets/publication_trend_line_chart.dart';

void main() {
  group('PublicationTrendLineChart', () {
    testWidgets('shows empty state message when data is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PublicationTrendLineChart(data: {})),
        ),
      );

      expect(find.text('No trend data available.'), findsOneWidget);
    });

    testWidgets('renders chart and Publications label with data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: PublicationTrendLineChart(data: {2020: 5, 2021: 12, 2022: 8}),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Publications'), findsOneWidget);
    });

    testWidgets('does not show empty state when data is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: PublicationTrendLineChart(data: {2022: 10}),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('No trend data available.'), findsNothing);
    });

    testWidgets('renders correctly with single data point', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: PublicationTrendLineChart(data: {2024: 100}),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('No trend data available.'), findsNothing);
      expect(find.text('Publications'), findsOneWidget);
    });
  });
}
