import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:openalex/providers/analytics_provider.dart';
import 'package:openalex/widgets/analytics/author_impact_chart.dart';

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
            child: const AuthorImpactChart(),
          ),
        ),
      ),
    );
  }

  testWidgets('empty data does not crash', (tester) async {
    when(() => mockProvider.authorImpact).thenReturn([]);

    await tester.pumpWidget(buildChart());
    expect(find.text('No author data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-empty data renders safely', (tester) async {
    when(() => mockProvider.authorImpact).thenReturn([
      AuthorImpact(name: 'Alice', paperCount: 10, totalCitations: 100),
      AuthorImpact(name: 'Bob', paperCount: 5, totalCitations: 50),
    ]);

    await tester.pumpWidget(buildChart());
    expect(find.byType(AuthorImpactChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero values do not crash', (tester) async {
    when(() => mockProvider.authorImpact).thenReturn([
      AuthorImpact(name: 'Alice', paperCount: 0, totalCitations: 0),
      AuthorImpact(name: 'Bob', paperCount: 0, totalCitations: 0),
    ]);

    await tester.pumpWidget(buildChart());
    expect(find.byType(AuthorImpactChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple items render safely', (tester) async {
    when(() => mockProvider.authorImpact).thenReturn([
      for (int i = 0; i < 20; i++)
        AuthorImpact(name: 'Author $i', paperCount: i, totalCitations: i * 10),
    ]);

    await tester.pumpWidget(buildChart());
    expect(find.byType(AuthorImpactChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long label does not crash', (tester) async {
    when(() => mockProvider.authorImpact).thenReturn([
      AuthorImpact(
        name: 'A Very Very Very Long Author Name Indeed',
        paperCount: 5,
        totalCitations: 20,
      ),
    ]);

    await tester.pumpWidget(buildChart());
    expect(find.byType(AuthorImpactChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
