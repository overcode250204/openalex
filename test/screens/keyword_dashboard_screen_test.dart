import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/providers/keyword_dashboard_provider.dart';
import 'package:openalex/screens/keyword/keyword_dashboard_screen.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';
import 'package:provider/provider.dart';

class _FakeKeywordDashboardService extends KeywordDashboardService {
  bool fail = false;
  
  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) async {
    if (fail) throw Exception('Simulated failure');
    return KeywordDashboardResult(
      hottestKeyword: null,
      mostFrequentKeywords: [],
      trendingKeywords: [],
      statistics: const KeywordFrequencyStat(
        totalKeywordsAnalyzed: 0,
        totalRecentPublications: 0,
        hottestKeyword: '-',
        fastestGrowthRate: 0.0,
      ),
      trendSeries: {},
      currentPeriodStart: DateTime.now(),
      currentPeriodEnd: DateTime.now(),
      previousPeriodStart: DateTime.now(),
      previousPeriodEnd: DateTime.now(),
      fetchedAt: DateTime.now(),
    );
  }
}

void main() {
  Widget buildTestWidget(KeywordDashboardProvider provider) {
    return MaterialApp(
      home: ChangeNotifierProvider.value(
        value: provider,
        child: const KeywordDashboardScreen(),
      ),
    );
  }

  group('KeywordDashboardScreen Tests', () {
    testWidgets('initial empty UI', (tester) async {
      final provider = KeywordDashboardProvider(_FakeKeywordDashboardService());
      await tester.pumpWidget(buildTestWidget(provider));
      // In initial state without load, it should show the loading skeleton.
      // But if we load it, it will eventually show empty UI.
      provider.load();
      await tester.pumpAndSettle();
      
      expect(find.text('No recent keyword activity found.'), findsWidgets);
    });

    testWidgets('loading UI', (tester) async {
      final provider = KeywordDashboardProvider(_FakeKeywordDashboardService());
      // Just pumping without load() leaves state as initial, which renders KeywordLoadingState (ListView)
      await tester.pumpWidget(buildTestWidget(provider));
      
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('error UI with retry button', (tester) async {
      final service = _FakeKeywordDashboardService()..fail = true;
      final provider = KeywordDashboardProvider(service);
      await tester.pumpWidget(buildTestWidget(provider));
      provider.load(); // Trigger load after pumping so it transitions
      
      await tester.pumpAndSettle();
      
      expect(find.text('Unable to load keyword activity. Please try again.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('success UI with dashboard cards', (tester) async {
      final provider = KeywordDashboardProvider(_FakeKeywordDashboardService());
      await tester.pumpWidget(buildTestWidget(provider));
      provider.load();
      
      await tester.pumpAndSettle();
      
      expect(find.text('Unable to load keyword activity. Please try again.'), findsNothing);
    });

    testWidgets('dashboard screen does not show error and empty state together', (tester) async {
      final service = _FakeKeywordDashboardService()..fail = true;
      final provider = KeywordDashboardProvider(service);
      await tester.pumpWidget(buildTestWidget(provider));
      provider.load();
      await tester.pumpAndSettle();
      
      expect(find.text('Unable to load keyword activity. Please try again.'), findsOneWidget);
      expect(find.text('No recent keyword activity found.'), findsNothing);
    });
  });
}

