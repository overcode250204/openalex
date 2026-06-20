import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _SuccessService extends OpenAlexKeywordService {
  @override
  Future<KeywordAnalysisResult> analyzeKeyword(String kw, {int fromYear = 2011, int? toYear}) async {
    return KeywordAnalysisResult(
      keyword: kw,
      trend: const [KeywordTrendPoint(year: 2024, count: 5)],
      relevantPapers: const [],
      mostCitedPapers: const [],
      latestPapers: const [],
      openAccessPapers: const [],
    );
  }
}

class _GenericErrorService extends OpenAlexKeywordService {
  @override
  Future<KeywordAnalysisResult> analyzeKeyword(String keyword, {int fromYear = 2011, int? toYear}) async {
    throw Exception('Network failure');
  }
}

class _KeywordNotFoundService extends OpenAlexKeywordService {
  @override
  Future<KeywordAnalysisResult> analyzeKeyword(String keyword, {int fromYear = 2011, int? toYear}) async {
    throw KeywordNotFoundException('Keyword "$keyword" was not found.');
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('KeywordAnalyzerViewModel – clear', () {
    test('clear resets result, error, and keyword', () async {
      final vm = KeywordAnalyzerViewModel(_SuccessService());

      await vm.analyze('AI');
      expect(vm.result, isNotNull);
      expect(vm.keyword, 'AI');

      vm.clear();

      expect(vm.result, isNull);
      expect(vm.errorMessage, isNull);
      expect(vm.keyword, '');
      expect(vm.isLoading, isFalse);
    });

    test('clear notifies listeners', () {
      final vm = KeywordAnalyzerViewModel(_SuccessService());
      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.clear();

      expect(notifyCount, 1);
    });
  });

  group('KeywordAnalyzerViewModel – generic exception', () {
    test(
      'analyze shows generic error for non-KeywordNotFoundException',
      () async {
        final vm = KeywordAnalyzerViewModel(_GenericErrorService());

        await vm.analyze('AI');

        expect(vm.isLoading, isFalse);
        expect(vm.result, isNull);
        expect(vm.errorMessage, isNotNull);
        expect(vm.errorMessage, isNot('Please enter an academic keyword.'));
      },
    );

    test(
      'analyze shows specific message for KeywordNotFoundException',
      () async {
        final vm = KeywordAnalyzerViewModel(_KeywordNotFoundService());

        await vm.analyze('obscure-term');

        expect(vm.errorMessage, contains('obscure-term'));
        expect(vm.result, isNull);
      },
    );
  });

  group('KeywordAnalyzerViewModel – retry', () {
    test('retry after clear does nothing useful (keyword is empty)', () async {
      final vm = KeywordAnalyzerViewModel(_SuccessService());
      await vm.analyze('AI');
      vm.clear();

      // After clear, keyword is empty → retry should reject without setting error
      await vm.retry();

      expect(vm.errorMessage, isNull);
    });

    test('retry after error re-calls service with same keyword', () async {
      var callCount = 0;
      final service = _CountingService(onCall: () => callCount++);
      final vm = KeywordAnalyzerViewModel(service);

      await vm.analyze('AI');
      await vm.retry();

      expect(callCount, 2);
      expect(vm.keyword, 'AI');
    });
  });

  group('KeywordAnalyzerViewModel – loading state', () {
    testWidgets('isLoading is true while analyzing, then false', (
      tester,
    ) async {
      final vm = KeywordAnalyzerViewModel(_SuccessService());
      final loadingStates = <bool>[];
      vm.addListener(() => loadingStates.add(vm.isLoading));

      await vm.analyze('Blockchain');

      expect(loadingStates, [true, false]);
    });
  });
}

// Counts how many times analyzeKeyword is called
class _CountingService extends OpenAlexKeywordService {
  final VoidCallback onCall;

  _CountingService({required this.onCall});

  @override
  Future<KeywordAnalysisResult> analyzeKeyword(String keyword, {int fromYear = 2011, int? toYear}) async {
    onCall();
    return KeywordAnalysisResult(
      keyword: keyword,
      trend: const [],
      relevantPapers: const [],
      mostCitedPapers: const [],
      latestPapers: const [],
      openAccessPapers: const [],
    );
  }
}
