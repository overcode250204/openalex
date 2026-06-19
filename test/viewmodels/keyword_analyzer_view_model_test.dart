import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';

class FakeKeywordService extends OpenAlexKeywordService {
  FakeKeywordService({this.result, this.error});

  final KeywordAnalysisResult? result;
  Object? error;
  String? requestedKeyword;
  int calls = 0;

  @override
  Future<KeywordAnalysisResult> analyzeKeyword(
    String keyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
    calls++;
    requestedKeyword = keyword;

    if (error != null) {
      throw error!;
    }

    return result ?? sampleResult(keyword);
  }

  @override
  Future<List<KeywordTrendPoint>> fetchKeywordTrend({
    required String keyword,
    int fromYear = 2011,
    int? toYear,
  }) async {
    if (error != null) throw error!;
    return [
      KeywordTrendPoint(year: fromYear, count: 10),
      KeywordTrendPoint(year: toYear ?? DateTime.now().year, count: 20),
    ];
  }
}

class FakeSuggestionService extends SuggestionService {
  FakeSuggestionService({this.suggestions = const []});

  final List<String> suggestions;
  final requestedQueries = <String>[];

  @override
  Future<List<String>> fetchKeywordSuggestions(String query) async {
    requestedQueries.add(query);
    return suggestions;
  }
}

void main() {
  group('KeywordAnalyzerViewModel', () {
    test('has initial state', () {
      final viewModel = KeywordAnalyzerViewModel(FakeKeywordService());

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.result, isNull);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.keyword, '');
    });

    test('rejects empty keyword without calling service', () async {
      final service = FakeKeywordService();
      final viewModel = KeywordAnalyzerViewModel(service);

      await viewModel.analyze('   ');

      expect(viewModel.errorMessage, 'Please enter an academic keyword.');
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.result, isNull);
      expect(service.calls, 0);
    });

    test('analyze success toggles loading and stores result', () async {
      final service = FakeKeywordService(result: sampleResult('AI'));
      final viewModel = KeywordAnalyzerViewModel(service);
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await viewModel.analyze('  AI  ');

      expect(service.requestedKeyword, 'AI');
      expect(loadingStates, [true, false]);
      expect(viewModel.keyword, 'AI');
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.result?.keyword, 'AI');
    });

    test('analyze failure exposes friendly KeywordNotFoundException', () async {
      final viewModel = KeywordAnalyzerViewModel(
        FakeKeywordService(error: KeywordNotFoundException('Not found.')),
      );

      await viewModel.analyze('AI');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.result, isNull);
      expect(viewModel.errorMessage, 'Not found.');
    });

    test('retry reuses the last valid keyword', () async {
      final service = FakeKeywordService(result: sampleResult('AI'));
      final viewModel = KeywordAnalyzerViewModel(service);

      await viewModel.analyze('AI');
      await viewModel.retry();

      expect(service.calls, 2);
      expect(service.requestedKeyword, 'AI');
    });

    test(
      'onQueryChanged shows and loads keyword suggestions after debounce',
      () async {
        final suggestionService = FakeSuggestionService(
          suggestions: const ['Machine learning', 'Deep learning'],
        );
        final viewModel = KeywordAnalyzerViewModel(
          FakeKeywordService(),
          suggestionService: suggestionService,
        );

        viewModel.onQueryChanged('machine');

        expect(viewModel.showKeywordSuggestions, isTrue);
        expect(viewModel.keywordSuggestions, isEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(suggestionService.requestedQueries, ['machine']);
        expect(viewModel.keywordSuggestions, [
          'Machine learning',
          'Deep learning',
        ]);
        expect(viewModel.showKeywordSuggestions, isTrue);
      },
    );

    test('empty query clears and hides keyword suggestions', () async {
      final viewModel = KeywordAnalyzerViewModel(FakeKeywordService());

      viewModel.onQueryChanged('machine');
      viewModel.onQueryChanged('');

      expect(viewModel.keywordSuggestions, isEmpty);
      expect(viewModel.showKeywordSuggestions, isFalse);
    });

    test('hideKeywordSuggestions hides without clearing suggestions', () async {
      final viewModel = KeywordAnalyzerViewModel(
        FakeKeywordService(),
        suggestionService: FakeSuggestionService(suggestions: const ['AI']),
      );

      viewModel.onQueryChanged('ai');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      viewModel.hideKeywordSuggestions();

      expect(viewModel.keywordSuggestions, ['AI']);
      expect(viewModel.showKeywordSuggestions, isFalse);
    });

    test('analyze and clear clear keyword suggestions', () async {
      final viewModel = KeywordAnalyzerViewModel(
        FakeKeywordService(),
        suggestionService: FakeSuggestionService(suggestions: const ['AI']),
      );

      viewModel.onQueryChanged('ai');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      await viewModel.analyze('AI');

      expect(viewModel.keywordSuggestions, isEmpty);
      expect(viewModel.showKeywordSuggestions, isFalse);

      viewModel.onQueryChanged('ai');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(viewModel.result, isNull);
      expect(viewModel.keywordSuggestions, isEmpty);
      expect(viewModel.showKeywordSuggestions, isFalse);
      expect(viewModel.isLoadingTrend, isFalse);
      expect(viewModel.hasTrendError, isFalse);
    });

    test(
      'updateKeywordTrendYearRange swaps if from > to and calls reload',
      () async {
        final service = FakeKeywordService(result: sampleResult('AI'));
        final viewModel = KeywordAnalyzerViewModel(service);

        await viewModel.analyze('AI');

        await viewModel.updateKeywordTrendYearRange(
          fromYear: 2022,
          toYear: 2020,
        );

        expect(viewModel.selectedFromYear, 2020);
        expect(viewModel.selectedToYear, 2022);
        expect(viewModel.result?.trend.length, 2);
        expect(viewModel.result?.trend.first.year, 2020);
        expect(viewModel.result?.trend.last.year, 2022);
      },
    );

    test('reloadKeywordTrend sets error on failure', () async {
      final service = FakeKeywordService(result: sampleResult('AI'));
      final viewModel = KeywordAnalyzerViewModel(service);

      await viewModel.analyze('AI');

      // Simulate failure
      service.error = Exception('Network error');

      await viewModel.reloadKeywordTrend();

      expect(viewModel.hasTrendError, isTrue);
      expect(viewModel.isLoadingTrend, isFalse);
    });
  });
}

KeywordAnalysisResult sampleResult(String keyword) {
  return KeywordAnalysisResult(
    keyword: keyword,
    trend: const [KeywordTrendPoint(year: 2024, count: 10)],
    relevantPapers: const [],
    mostCitedPapers: const [
      KeywordAnalysisPaper(
        id: 'W1',
        title: 'Top Paper',
        publicationYear: 2024,
        publicationDate: '2024-01-01',
        sourceName: 'Journal',
        doi: null,
        landingPageUrl: null,
        pdfUrl: null,
        citedByCount: 10,
        isOpenAccess: true,
      ),
    ],
    latestPapers: const [],
    openAccessPapers: const [],
  );
}
