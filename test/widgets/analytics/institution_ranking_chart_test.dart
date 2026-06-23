import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:openalex/viewmodels/analytics_view_model.dart';
import 'package:openalex/widgets/analytics/institution_ranking_chart.dart';

class MockAnalyticsViewModel extends Mock implements AnalyticsViewModel {}

void main() {
  late MockAnalyticsViewModel mockProvider;

  setUp(() {
    mockProvider = MockAnalyticsViewModel();
  });

  Widget buildChart() {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 2000,
          height: 1000,
          child: ChangeNotifierProvider<AnalyticsViewModel>.value(
            value: mockProvider,
            child: const InstitutionRankingChart(),
          ),
        ),
      ),
    );
  }

  testWidgets('loading state renders safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(true);
    when(() => mockProvider.institutionRanking).thenReturn({});

    await tester.pumpWidget(buildChart());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty data does not crash', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.institutionRanking).thenReturn({});

    await tester.pumpWidget(buildChart());
    expect(find.byType(InstitutionRankingChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-empty data renders safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(
      () => mockProvider.institutionRanking,
    ).thenReturn({'MIT': 100, 'Stanford': 80});

    await tester.pumpWidget(buildChart());
    expect(find.byType(InstitutionRankingChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero values do not crash', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(
      () => mockProvider.institutionRanking,
    ).thenReturn({'MIT': 0, 'Stanford': 0});

    await tester.pumpWidget(buildChart());
    expect(find.byType(InstitutionRankingChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple items render safely', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(
      () => mockProvider.institutionRanking,
    ).thenReturn({for (int i = 0; i < 20; i++) 'Institution $i': i * 10});

    await tester.pumpWidget(buildChart());
    expect(find.byType(InstitutionRankingChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long label does not crash', (tester) async {
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.institutionRanking).thenReturn({
      'Massachusetts Institute of Technology (MIT)': 50,
      'University of California, Berkeley': 30,
    });

    await tester.pumpWidget(buildChart());
    expect(find.byType(InstitutionRankingChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
