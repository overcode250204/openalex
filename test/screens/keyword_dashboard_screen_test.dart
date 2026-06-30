import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';
import 'package:openalex/models/keyword/keyword_overview.dart';
import 'package:openalex/screens/keyword/keyword_dashboard_screen.dart';
import 'package:openalex/services/firebase/remote_config_service.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:openalex/viewmodels/keyword_dashboard_view_model.dart';
import 'package:openalex/viewmodels/remote_config_view_model.dart';
import 'package:openalex/widgets/state/loading_widget.dart';
import 'package:provider/provider.dart';

class _FakeKeywordDashboardService extends KeywordDashboardService {
  bool fail = false;
  int callCount = 0;
  KeywordDashboardResult? result;

  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) async {
    callCount++;
    if (fail) throw Exception('Simulated failure');
    return result ??
        KeywordDashboardResult(
          hottestKeyword: null,
          mostFrequentKeywords: const [],
          trendingKeywords: const [],
          statistics: const KeywordFrequencyStat(
            totalKeywordsAnalyzed: 0,
            totalRecentPublications: 0,
            hottestKeyword: '-',
            fastestGrowthRate: 0,
          ),
          trendSeries: const {},
          currentPeriodStart: DateTime.now(),
          currentPeriodEnd: DateTime.now(),
          previousPeriodStart: DateTime.now(),
          previousPeriodEnd: DateTime.now(),
          fetchedAt: DateTime.now(),
        );
  }
}

class _MutableRemoteConfigService implements AppRemoteConfigService {
  _MutableRemoteConfigService({this.maxKeywords = 5, this.nextMaxKeywords});

  int maxKeywords;
  int? nextMaxKeywords;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> fetchAndActivate() async {
    final next = nextMaxKeywords;
    if (next != null) {
      maxKeywords = next;
      nextMaxKeywords = null;
    }
    return true;
  }

  @override
  int get maxJournalsDisplayed => 10;

  @override
  int get maxKeywordsDisplayed => maxKeywords;
}

KeywordOverview _keyword(String id, int count) {
  return KeywordOverview(
    id: id,
    name: id.toUpperCase(),
    currentPeriodCount: count,
    previousPeriodCount: count ~/ 2,
    growthRate: count.toDouble(),
    hotScore: count.toDouble(),
    status: KeywordStatus.hot,
  );
}

KeywordDashboardResult _keywordResult() {
  final frequentKeywords = [
    _keyword('f1', 40),
    _keyword('f2', 30),
    _keyword('f3', 20),
    _keyword('f4', 10),
  ];
  final trendingKeywords = [
    _keyword('t1', 40),
    _keyword('t2', 30),
    _keyword('t3', 20),
    _keyword('t4', 10),
  ];

  return KeywordDashboardResult(
    hottestKeyword: frequentKeywords.first,
    mostFrequentKeywords: frequentKeywords,
    trendingKeywords: trendingKeywords,
    statistics: const KeywordFrequencyStat(
      totalKeywordsAnalyzed: 4,
      totalRecentPublications: 100,
      hottestKeyword: 'F1',
      fastestGrowthRate: 40,
    ),
    trendSeries: const {},
    currentPeriodStart: DateTime(2026, 1),
    currentPeriodEnd: DateTime(2026, 6),
    previousPeriodStart: DateTime(2025, 7),
    previousPeriodEnd: DateTime(2025, 12),
    fetchedAt: DateTime(2026, 6, 25),
  );
}

void main() {
  Widget buildTestWidget(
    KeywordDashboardViewModel viewModel, {
    RemoteConfigViewModel? remoteConfigViewModel,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: viewModel),
        ChangeNotifierProvider(
          create: (_) => KeywordAnalyzerViewModel(OpenAlexKeywordService()),
        ),
        Provider(create: (_) => SuggestionService()),
        if (remoteConfigViewModel != null)
          ChangeNotifierProvider.value(value: remoteConfigViewModel),
      ],
      child: const MaterialApp(home: KeywordDashboardScreen()),
    );
  }

  group('KeywordDashboardScreen', () {
    testWidgets('does not request data when merely constructed', (
      tester,
    ) async {
      final service = _FakeKeywordDashboardService();
      final viewModel = KeywordDashboardViewModel(service);

      await tester.pumpWidget(buildTestWidget(viewModel));

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(service.callCount, 0);
    });

    testWidgets('shows empty state after an explicit load', (tester) async {
      final viewModel = KeywordDashboardViewModel(
        _FakeKeywordDashboardService(),
      );
      await viewModel.load();

      await tester.pumpWidget(buildTestWidget(viewModel));

      expect(find.text('No recent keyword activity found.'), findsOneWidget);
    });

    testWidgets('shows error and Try Again after load failure', (tester) async {
      final service = _FakeKeywordDashboardService()..fail = true;
      final viewModel = KeywordDashboardViewModel(service);
      await viewModel.load();

      await tester.pumpWidget(buildTestWidget(viewModel));

      expect(
        find.text('Unable to load keyword activity. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('No recent keyword activity found.'), findsNothing);
    });

    testWidgets('Try Again is the only automatic retry path after an error', (
      tester,
    ) async {
      final service = _FakeKeywordDashboardService()..fail = true;
      final viewModel = KeywordDashboardViewModel(service);
      await viewModel.load();
      await viewModel.load();
      expect(service.callCount, 1);

      await tester.pumpWidget(buildTestWidget(viewModel));
      service.fail = false;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(service.callCount, 2);
      expect(find.text('No recent keyword activity found.'), findsOneWidget);
    });

    testWidgets('Remote Config fetch changes visible keyword limit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final remoteConfigService = _MutableRemoteConfigService(
        maxKeywords: 3,
        nextMaxKeywords: 1,
      );
      final remoteConfigViewModel = RemoteConfigViewModel(remoteConfigService);
      final service = _FakeKeywordDashboardService()..result = _keywordResult();
      final viewModel = KeywordDashboardViewModel(
        service,
        remoteConfigService: remoteConfigService,
      );
      await viewModel.load();

      await tester.pumpWidget(
        buildTestWidget(
          viewModel,
          remoteConfigViewModel: remoteConfigViewModel,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('most_frequent_keyword_f2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('most_frequent_keyword_f4')),
        findsNothing,
      );

      await remoteConfigViewModel.fetchAndActivate();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('most_frequent_keyword_f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('most_frequent_keyword_f2')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('trending_keyword_t1')), findsOneWidget);
      expect(find.byKey(const ValueKey('trending_keyword_t2')), findsNothing);
    });
  });
}
