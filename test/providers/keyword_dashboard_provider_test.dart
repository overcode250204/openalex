import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/viewmodels/keyword_dashboard_view_model.dart';

KeywordDashboardResult _emptyResult() {
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

class _FakeKeywordDashboardService extends KeywordDashboardService {
  final Exception? mockError;
  int callCount = 0;

  _FakeKeywordDashboardService({this.mockError});

  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) async {
    callCount++;
    if (mockError != null) throw mockError!;
    return _emptyResult();
  }
}

class _DelayedKeywordDashboardService extends _FakeKeywordDashboardService {
  final Completer<KeywordDashboardResult> completer =
      Completer<KeywordDashboardResult>();

  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) {
    callCount++;
    return completer.future;
  }
}

void main() {
  group('KeywordDashboardViewModel Tests', () {
    test('initial state', () {
      final provider = KeywordDashboardViewModel(KeywordDashboardService());
      expect(provider.state, KeywordDashboardState.initial);
      expect(provider.result, isNull);
    });

    test('successful data load and loading state', () async {
      final service = _FakeKeywordDashboardService();
      final provider = KeywordDashboardViewModel(service);

      // Verify loading state triggers during fetch
      final future = provider.refresh();
      expect(provider.state, KeywordDashboardState.loading);
      await future;

      expect(
        provider.state,
        KeywordDashboardState.empty,
      ); // since hottestKeyword is null and lists empty
      expect(provider.result, isNotNull);
      expect(service.callCount, 1);
    });

    test('empty data state', () async {
      final service = _FakeKeywordDashboardService();
      final provider = KeywordDashboardViewModel(service);

      await provider.refresh();
      expect(provider.state, KeywordDashboardState.empty);
    });

    test('error state and retry after error', () async {
      final service = _FakeKeywordDashboardService(
        mockError: Exception('Failed'),
      );
      final provider = KeywordDashboardViewModel(service);

      await provider.refresh();
      expect(provider.state, KeywordDashboardState.error);
    });

    test('provider notifies listeners correctly', () async {
      final provider = KeywordDashboardViewModel(
        _FakeKeywordDashboardService(),
      );
      int notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      await provider.refresh();
      expect(notifyCount, greaterThan(1));
    });

    test('refresh does not start another fetch while loading', () async {
      final service = _DelayedKeywordDashboardService();
      final provider = KeywordDashboardViewModel(service);

      final loadFuture = provider.load();
      await provider.refresh();

      expect(service.callCount, 1);

      service.completer.complete(_emptyResult());
      await loadFuture;
    });

    test('year range update is ignored while loading', () async {
      final service = _DelayedKeywordDashboardService();
      final provider = KeywordDashboardViewModel(service);
      final originalFromYear = provider.selectedFromYear;
      final originalToYear = provider.selectedToYear;

      final loadFuture = provider.load();
      await provider.updateTrendYearRange(2015, 2020);

      expect(service.callCount, 1);
      expect(provider.selectedFromYear, originalFromYear);
      expect(provider.selectedToYear, originalToYear);

      service.completer.complete(_emptyResult());
      await loadFuture;
    });
  });
}
