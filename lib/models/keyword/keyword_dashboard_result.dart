import 'keyword_frequency_stat.dart';
import 'keyword_overview.dart';
import 'keyword_trend_point.dart';

class KeywordDashboardResult {
  final KeywordOverview? hottestKeyword;
  final List<KeywordOverview> mostFrequentKeywords;
  final List<KeywordOverview> trendingKeywords;
  final KeywordFrequencyStat statistics;
  final Map<String, List<KeywordTrendPoint>> trendSeries;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime previousPeriodStart;
  final DateTime previousPeriodEnd;
  final DateTime fetchedAt;

  const KeywordDashboardResult({
    required this.hottestKeyword,
    required this.mostFrequentKeywords,
    required this.trendingKeywords,
    required this.statistics,
    required this.trendSeries,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.previousPeriodStart,
    required this.previousPeriodEnd,
    required this.fetchedAt,
  });

  bool get isEmpty => hottestKeyword == null || mostFrequentKeywords.isEmpty;
}
