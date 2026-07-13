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

  KeywordDashboardResult copyWith({
    KeywordOverview? hottestKeyword,
    List<KeywordOverview>? mostFrequentKeywords,
    List<KeywordOverview>? trendingKeywords,
    KeywordFrequencyStat? statistics,
    Map<String, List<KeywordTrendPoint>>? trendSeries,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? previousPeriodStart,
    DateTime? previousPeriodEnd,
    DateTime? fetchedAt,
  }) {
    return KeywordDashboardResult(
      hottestKeyword: hottestKeyword ?? this.hottestKeyword,
      mostFrequentKeywords: mostFrequentKeywords ?? this.mostFrequentKeywords,
      trendingKeywords: trendingKeywords ?? this.trendingKeywords,
      statistics: statistics ?? this.statistics,
      trendSeries: trendSeries ?? this.trendSeries,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      previousPeriodStart: previousPeriodStart ?? this.previousPeriodStart,
      previousPeriodEnd: previousPeriodEnd ?? this.previousPeriodEnd,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
