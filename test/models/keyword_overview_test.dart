import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_overview.dart';

void main() {
  group('KeywordOverview Tests', () {
    test('maps nullable/default fields correctly', () {
      final overview = KeywordOverview(
        id: 'k1',
        name: 'Test',
        currentPeriodCount: 0,
        previousPeriodCount: 0,
        growthRate: 0.0,
        hotScore: 0.0,
        status: KeywordStatus.stable,
      );
      
      expect(overview.id, 'k1');
      expect(overview.name, 'Test');
      expect(overview.currentPeriodCount, 0);
      expect(overview.previousPeriodCount, 0);
      expect(overview.growthRate, 0.0);
      expect(overview.hotScore, 0.0);
      expect(overview.status, KeywordStatus.stable);
    });

    test('copyWith works', () {
      final overview = KeywordOverview(
        id: 'k1',
        name: 'Test',
        currentPeriodCount: 100,
        previousPeriodCount: 50,
        growthRate: 0.0,
        hotScore: 0.0,
        status: KeywordStatus.stable,
      );
      
      final copy = overview.copyWith(hotScore: 5.0);
      expect(copy.hotScore, 5.0);
      expect(copy.id, 'k1');
    });
  });
}
