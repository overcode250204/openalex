import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';

void main() {
  group('KeywordTrendPoint', () {
    test('parses group_by response and sorts by year ascending', () {
      final points = KeywordTrendPoint.parseGroupBy([
        {'key': '2024', 'count': 12},
        {'key': '2020', 'count': 3},
        {'key_display_name': '2022', 'count': 8},
      ]);

      expect(points.map((point) => point.year), [2020, 2022, 2024]);
      expect(points.map((point) => point.count), [3, 8, 12]);
    });

    test('skips invalid and old years', () {
      final points = KeywordTrendPoint.parseGroupBy([
        {'key': 'unknown', 'count': 99},
        {'key': '1899', 'count': 10},
        {'key': '2024', 'count': 12},
      ]);

      expect(points, hasLength(1));
      expect(points.single.year, 2024);
    });

    test('limits chart points to latest years', () {
      final points = List.generate(
        20,
        (index) => KeywordTrendPoint(year: 2000 + index, count: index),
      );

      final latest = KeywordTrendPoint.latestPoints(points, limit: 15);

      expect(latest, hasLength(15));
      expect(latest.first.year, 2005);
      expect(latest.last.year, 2019);
    });
  });
}
