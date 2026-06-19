import 'keyword_analysis_paper.dart';
import 'keyword_trend_point.dart';
import 'openalex_keyword.dart';

class KeywordAnalysisResult {
  final String keyword;
  final OpenAlexKeyword? resolvedKeyword;
  final List<KeywordTrendPoint> trend;
  final List<KeywordAnalysisPaper> relevantPapers;
  final List<KeywordAnalysisPaper> mostCitedPapers;
  final List<KeywordAnalysisPaper> latestPapers;
  final List<KeywordAnalysisPaper> openAccessPapers;

  final Map<String, int> topAuthors;
  final Map<String, int> topSources;

  const KeywordAnalysisResult({
    required this.keyword,
    this.resolvedKeyword,
    required this.trend,
    required this.relevantPapers,
    required this.mostCitedPapers,
    required this.latestPapers,
    required this.openAccessPapers,
    this.topAuthors = const {},
    this.topSources = const {},
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

  KeywordAnalysisResult copyWith({
    List<KeywordTrendPoint>? trend,
    List<KeywordAnalysisPaper>? relevantPapers,
    List<KeywordAnalysisPaper>? mostCitedPapers,
    List<KeywordAnalysisPaper>? latestPapers,
    List<KeywordAnalysisPaper>? openAccessPapers,
    Map<String, int>? topAuthors,
    Map<String, int>? topSources,
  }) {
    return KeywordAnalysisResult(
      keyword: keyword,
      resolvedKeyword: resolvedKeyword,
      trend: trend ?? this.trend,
      relevantPapers: relevantPapers ?? this.relevantPapers,
      mostCitedPapers: mostCitedPapers ?? this.mostCitedPapers,
      latestPapers: latestPapers ?? this.latestPapers,
      openAccessPapers: openAccessPapers ?? this.openAccessPapers,
      topAuthors: topAuthors ?? this.topAuthors,
      topSources: topSources ?? this.topSources,
    );
  }
}
