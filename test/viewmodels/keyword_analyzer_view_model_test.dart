import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';

class FakeKeywordService extends OpenAlexKeywordService {
  FakeKeywordService({this.result, this.error});

  final KeywordAnalysisResult? result;
  final Object? error;
  String? requestedKeyword;
  int calls = 0;

  @override
  Future<KeywordAnalysisResult> analyzeKeyword(String keyword) async {
    calls++;
    requestedKeyword = keyword;

    if (error != null) {
      throw error!;
    }

    return result ?? sampleResult(keyword);
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

    test('analyze failure exposes friendly error', () async {
      final viewModel = KeywordAnalyzerViewModel(
        FakeKeywordService(error: Exception('boom')),
      );

      await viewModel.analyze('AI');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.result, isNull);
      expect(
        viewModel.errorMessage,
        'Unable to analyze keyword. Please try again.',
      );
    });

    test('retry reuses the last valid keyword', () async {
      final service = FakeKeywordService(result: sampleResult('AI'));
      final viewModel = KeywordAnalyzerViewModel(service);

      await viewModel.analyze('AI');
      await viewModel.retry();

      expect(service.calls, 2);
      expect(service.requestedKeyword, 'AI');
    });
  });
}

KeywordAnalysisResult sampleResult(String keyword) {
  return KeywordAnalysisResult(
    keyword: keyword,
    trend: const [KeywordTrendPoint(year: 2024, count: 10)],
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
