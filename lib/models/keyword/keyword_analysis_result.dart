import 'keyword_analysis_paper.dart';
import 'keyword_trend_point.dart';
import 'openalex_keyword.dart';

// Dummy classes for optional fields until fully implemented if needed
class TopAuthorItem {}

class TopSourceItem {}

class TopKeywordItem {}

class KeywordAnalysisResult {
  final String keyword;
  final OpenAlexKeyword? resolvedKeyword;
  final List<KeywordTrendPoint> trend;
  final List<KeywordAnalysisPaper> relevantPapers;
  final List<KeywordAnalysisPaper> mostCitedPapers;
  final List<KeywordAnalysisPaper> latestPapers;
  final List<KeywordAnalysisPaper> openAccessPapers;

  final List<TopAuthorItem> topAuthors;
  final List<TopSourceItem> topSources;
  final List<TopKeywordItem> relatedKeywords;

  const KeywordAnalysisResult({
    required this.keyword,
    this.resolvedKeyword,
    required this.trend,
    required this.relevantPapers,
    required this.mostCitedPapers,
    required this.latestPapers,
    required this.openAccessPapers,
    this.topAuthors = const [],
    this.topSources = const [],
    this.relatedKeywords = const [],
  });

  bool get isEmpty {
    return trend.isEmpty &&
        relevantPapers.isEmpty &&
        mostCitedPapers.isEmpty &&
        latestPapers.isEmpty &&
        openAccessPapers.isEmpty;
  }

  int get totalPublications {
    return resolvedKeyword?.worksCount ??
        trend.fold(0, (sum, point) => sum + point.count);
  }

  KeywordTrendPoint? get peakYear {
    if (trend.isEmpty) return null;
    return trend.reduce((a, b) => a.count >= b.count ? a : b);
  }

  KeywordAnalysisPaper? get mostCitedPaper {
    if (mostCitedPapers.isEmpty) return null;
    return mostCitedPapers.reduce(
      (a, b) => a.citedByCount >= b.citedByCount ? a : b,
    );
  }
}
