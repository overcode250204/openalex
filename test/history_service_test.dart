import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/services/history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SearchHistoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SearchHistoryService();
  });

  group('SearchHistoryService', () {
    test('adds newest searches first and ignores blank keywords', () async {
      await service.addHistory('Artificial Intelligence');
      await service.addHistory('Cybersecurity');
      await service.addHistory('   ');

      expect(await service.getHistory(), [
        'Cybersecurity',
        'Artificial Intelligence',
      ]);
    });

    test(
      'moves duplicate keyword to the front without duplicating it',
      () async {
        await service.addHistory('AI');
        await service.addHistory('Blockchain');
        await service.addHistory('AI');

        expect(await service.getHistory(), ['AI', 'Blockchain']);
      },
    );

    test('keeps at most ten history entries', () async {
      for (var index = 0; index < 12; index++) {
        await service.addHistory('Topic $index');
      }

      final history = await service.getHistory();

      expect(history, hasLength(10));
      expect(history.first, 'Topic 11');
      expect(history.last, 'Topic 2');
      expect(history, isNot(contains('Topic 0')));
      expect(history, isNot(contains('Topic 1')));
    });

    test('removes one keyword and clears all history', () async {
      await service.addHistory('AI');
      await service.addHistory('Data Science');

      await service.removeHistory('AI');

      expect(await service.getHistory(), ['Data Science']);

      await service.clearHistory();

      expect(await service.getHistory(), isEmpty);
    });
  });
}
