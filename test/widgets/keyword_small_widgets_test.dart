import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/widgets/keyword/keyword_stat_card.dart';
import 'package:openalex/widgets/keyword/hot_keyword_hero_card.dart';
import 'package:openalex/widgets/keyword/charts/keyword_chart_error_state.dart';
import 'package:openalex/widgets/keyword/charts/keyword_chart_skeleton.dart';
import 'package:openalex/widgets/keyword/charts/keyword_chart_empty_state.dart';
import 'package:openalex/widgets/keyword/keyword_empty_state.dart';
import 'package:openalex/models/keyword/keyword_overview.dart';

void main() {
  group('Smaller Keyword Widgets Tests', () {
    testWidgets('KeywordStatCard renders required data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KeywordStatCard(
              label: 'Test Label',
              value: 'Test Value',
              icon: Icons.abc,
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Value'), findsOneWidget);
      expect(find.byIcon(Icons.abc), findsOneWidget);
    });

    testWidgets('HotKeywordHeroCard renders keyword and metric', (
      tester,
    ) async {
      final keyword = KeywordOverview(
        id: 'k1',
        name: 'Super Hot Keyword',
        currentPeriodCount: 100,
        previousPeriodCount: 0,
        growthRate: 150.0,
        hotScore: 0.0,
        status: KeywordStatus.hot,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HotKeywordHeroCard(
              keyword: keyword,
              onViewDetail: () {},
              onShowCalculation: () {},
            ),
          ),
        ),
      );

      expect(find.text('Super Hot Keyword'), findsOneWidget);
      expect(find.textContaining('Growth:'), findsOneWidget);
    });

    testWidgets('KeywordChartErrorState calls retry', (tester) async {
      bool retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeywordChartErrorState(
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      final retryButton = find.byType(TextButton);
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);

      expect(retryCalled, isTrue);
    });

    testWidgets('empty and skeleton widgets render without exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const KeywordChartSkeleton(),
                  const KeywordChartEmptyState(),
                  KeywordEmptyState(onRefresh: () async {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(KeywordChartSkeleton), findsOneWidget);
      expect(find.byType(KeywordChartEmptyState), findsOneWidget);
      expect(find.byType(KeywordEmptyState), findsOneWidget);
    });
  });
}
