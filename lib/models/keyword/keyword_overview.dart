import 'keyword_trend_point.dart';

enum KeywordStatus { hot, emerging, stable, declining }

class KeywordOverview {
  final String id;
  final String name;
  final int currentPeriodCount;
  final int previousPeriodCount;
  final double growthRate;
  final double hotScore;
  final KeywordStatus status;
  final List<KeywordTrendPoint> trend;

  const KeywordOverview({
    required this.id,
    required this.name,
    required this.currentPeriodCount,
    required this.previousPeriodCount,
    required this.growthRate,
    required this.hotScore,
    required this.status,
    this.trend = const [],
  });

  KeywordOverview copyWith({double? hotScore, List<KeywordTrendPoint>? trend}) {
    return KeywordOverview(
      id: id,
      name: name,
      currentPeriodCount: currentPeriodCount,
      previousPeriodCount: previousPeriodCount,
      growthRate: growthRate,
      hotScore: hotScore ?? this.hotScore,
      status: status,
      trend: trend ?? this.trend,
    );
  }
}
