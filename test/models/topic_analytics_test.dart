import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/analytics/topic_analytics.dart';

void main() {
  test('average citations uses every analyzed work', () {
    const analytics = TopicAnalytics(
      publicationTrend: {},
      topKeywords: {},
      institutionRanking: {},
      countryOutput: {},
      analyzedWorks: 4,
      totalCitations: 25,
    );

    expect(analytics.averageCitations, 6.25);
  });

  test('empty analytics has no average or influential paper', () {
    final analytics = TopicAnalytics.empty();

    expect(analytics.totalWorks, 0);
    expect(analytics.averageCitations, isNull);
    expect(analytics.mostInfluentialPaper, isNull);
    expect(analytics.topAuthors, isEmpty);
    expect(analytics.topJournals, isEmpty);
    expect(analytics.publicationTrend, isEmpty);
  });
}
