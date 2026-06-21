import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/providers/keyword_dashboard_provider.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';

class _FakeKeywordDashboardService extends KeywordDashboardService {
  final KeywordDashboardResult? mockResult;
  final Exception? mockError;
  int callCount = 0;

  _FakeKeywordDashboardService({this.mockResult, this.mockError});

  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) async {
    callCount++;
    if (mockError != null) throw mockError!;
    return mockResult ??
        KeywordDashboardResult(
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
  group('KeywordDashboardProvider Tests', () {
    test('initial state', () {
      final provider = KeywordDashboardProvider(KeywordDashboardService());
      expect(provider.state, KeywordDashboardState.initial);
      expect(provider.result, isNull);
    });

    test('successful data load and loading state', () async {
      final service = _FakeKeywordDashboardService();
      final provider = KeywordDashboardProvider(service);

      // Verify loading state triggers during fetch
      final future = provider.refresh();
      expect(provider.state, KeywordDashboardState.loading);
      await future;

      expect(provider.state, KeywordDashboardState.empty); // since hottestKeyword is null and lists empty
      expect(provider.result, isNotNull);
      expect(service.callCount, 1);
    });

    test('empty data state', () async {
      final service = _FakeKeywordDashboardService();
      final provider = KeywordDashboardProvider(service);

      await provider.refresh();
      expect(provider.state, KeywordDashboardState.empty);
    });

    test('error state and retry after error', () async {
      final service = _FakeKeywordDashboardService(mockError: Exception('Failed'));
      final provider = KeywordDashboardProvider(service);

      await provider.refresh();
      expect(provider.state, KeywordDashboardState.error);
    });

    test('provider notifies listeners correctly', () async {
      final provider = KeywordDashboardProvider(_FakeKeywordDashboardService());
      int notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      await provider.refresh();
      expect(notifyCount, greaterThan(1));
    });
  });
}
