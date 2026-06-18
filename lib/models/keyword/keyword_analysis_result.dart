import 'keyword_analysis_paper.dart';
import 'keyword_trend_point.dart';

class KeywordAnalysisResult {
  final String keyword;
  final List<KeywordTrendPoint> trend;
  final List<KeywordAnalysisPaper> mostCitedPapers;
  final List<KeywordAnalysisPaper> latestPapers;
  final List<KeywordAnalysisPaper> openAccessPapers;

  const KeywordAnalysisResult({
    required this.keyword,
    required this.trend,
    required this.mostCitedPapers,
    required this.latestPapers,
    required this.openAccessPapers,
  });

  bool get isEmpty {
    return trend.isEmpty &&
        mostCitedPapers.isEmpty &&
        latestPapers.isEmpty &&
        openAccessPapers.isEmpty;
  }

  int get totalPublications {
    return trend.fold(0, (sum, point) => sum + point.count);
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
