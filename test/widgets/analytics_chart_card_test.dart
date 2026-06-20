import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/widgets/analytics_chart_card.dart';

void main() {
  testWidgets('AnalyticsChartCard renders title subtitle dropdown and child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnalyticsChartCard(
            title: 'Keyword Trend',
            subtitle: 'Number of papers with this keyword by publication year.',
            dropdownText: 'Yearly',
            child: Text('Chart child'),
          ),
        ),
      ),
    );

    expect(find.text('Keyword Trend'), findsOneWidget);
    expect(
      find.text('Number of papers with this keyword by publication year.'),
      findsOneWidget,
    );
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Chart child'), findsOneWidget);
  });
}
