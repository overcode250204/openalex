import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:openalex/providers/analytics_provider.dart';
import 'package:openalex/widgets/analytics/country_output_chart.dart';

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
            child: const CountryOutputChart(),
          ),
        ),
      ),
    );
  }

  testWidgets('loading state renders safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(true);
    when(() => mockProvider.countryOutput).thenReturn({});

    await tester.pumpWidget(buildChart());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty data does not crash', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.countryOutput).thenReturn({});

    await tester.pumpWidget(buildChart());
    expect(find.byType(CountryOutputChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-empty data renders safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.countryOutput).thenReturn({
      'USA': 100,
      'UK': 80,
    });

    await tester.pumpWidget(buildChart());
    expect(find.byType(CountryOutputChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero values do not crash', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.countryOutput).thenReturn({
      'USA': 0,
      'UK': 0,
    });

    await tester.pumpWidget(buildChart());
    expect(find.byType(CountryOutputChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple items render safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.countryOutput).thenReturn({
      for (int i = 0; i < 20; i++) 'Country $i': i * 10,
    });

    await tester.pumpWidget(buildChart());
    expect(find.byType(CountryOutputChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long label does not crash', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.countryOutput).thenReturn({
      'The United Kingdom of Great Britain and Northern Ireland': 50,
      'Another Very Very Very Long Country Name': 30,
    });

    await tester.pumpWidget(buildChart());
    expect(find.byType(CountryOutputChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
