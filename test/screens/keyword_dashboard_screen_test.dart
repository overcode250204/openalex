import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';
import 'package:openalex/screens/keyword/keyword_dashboard_screen.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/viewmodels/keyword_dashboard_view_model.dart';
import 'package:openalex/widgets/state/loading_widget.dart';
import 'package:provider/provider.dart';

class _FakeKeywordDashboardService extends KeywordDashboardService {
  bool fail = false;
  int callCount = 0;

  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) async {
    callCount++;
    if (fail) throw Exception('Simulated failure');
    return KeywordDashboardResult(
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

void main() {
  Widget buildTestWidget(KeywordDashboardViewModel viewModel) {
    return MaterialApp(
      home: ChangeNotifierProvider.value(
        value: viewModel,
        child: const KeywordDashboardScreen(),
      ),
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
  });
}
