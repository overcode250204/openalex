import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:openalex/providers/analytics_provider.dart';
import 'package:openalex/widgets/analytics/citation_trend_chart.dart';

class MockAnalyticsProvider extends Mock implements AnalyticsProvider {}

void main() {
  late MockAnalyticsProvider mockProvider;

  setUp(() {
    mockProvider = MockAnalyticsProvider();
  });

  Widget buildChart() {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 2000,
          height: 1000,
          child: ChangeNotifierProvider<AnalyticsProvider>.value(
            value: mockProvider,
            child: const CitationTrendChart(),
          ),
        ),
      ),
    );
  }

  testWidgets('loading state renders safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(true);
    when(() => mockProvider.publicationTrend).thenReturn({});

    await tester.pumpWidget(buildChart());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty data does not crash', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.publicationTrend).thenReturn({});

    await tester.pumpWidget(buildChart());
    expect(find.text('No publication trend data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-empty data renders safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.publicationTrend).thenReturn({
      2020: 10,
      2021: 15,
      2022: 20,
    });

    await tester.pumpWidget(buildChart());
    expect(find.byType(CitationTrendChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero values do not crash', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.publicationTrend).thenReturn({
      2020: 0,
      2021: 0,
    });

    await tester.pumpWidget(buildChart());
    expect(find.byType(CitationTrendChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple items render safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.publicationTrend).thenReturn({
      for (int i = 2000; i <= 2023; i++) i: i * 2,
    });

    await tester.pumpWidget(buildChart());
    expect(find.byType(CitationTrendChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
