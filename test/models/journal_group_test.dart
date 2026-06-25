import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication/journal_group.dart';
import 'package:openalex/models/publication/publication.dart';

Publication _publication({
  required String title,
  String? journal,
  int citations = 0,
}) {
  return Publication(
    id: title,
    title: title,
    publicationYear: null,
    citedByCount: citations,
    journalName: journal,
    doi: null,
    abstractText: null,
    authors: const [],
    referencedWorkIds: const [],
    relatedWorkIds: const [],
  );
}

void main() {
  group('JournalGroup.groupByJournal', () {
    test('ranks journals from highest to lowest publication count', () {
      final groups = JournalGroup.groupByJournal([
        _publication(title: 'A1', journal: 'Journal A'),
        _publication(title: 'B1', journal: 'Journal B'),
        _publication(title: 'A2', journal: 'Journal A'),
        _publication(title: 'A3', journal: 'Journal A'),
        _publication(title: 'B2', journal: 'Journal B'),
      ]);

      expect(groups.map((g) => g.journalName).toList(), [
        'Journal A',
        'Journal B',
      ]);
      expect(groups.map((g) => g.count).toList(), [3, 2]);
    });

    test('breaks ties alphabetically when counts are equal', () {
      final groups = JournalGroup.groupByJournal([
        _publication(title: 'Z1', journal: 'Zeta Journal'),
        _publication(title: 'A1', journal: 'Alpha Journal'),
      ]);

      expect(groups.map((g) => g.journalName).toList(), [
        'Alpha Journal',
        'Zeta Journal',
      ]);
    });

    test(
      'buckets publications with missing or blank journal info safely',
      () {
        final groups = JournalGroup.groupByJournal([
          _publication(title: 'P1', journal: null),
          _publication(title: 'P2', journal: '   '),
          _publication(title: 'P3', journal: 'Known Journal'),
        ]);

        final unknown = groups.singleWhere(
          (g) => g.journalName == 'Unknown journal',
        );
        expect(unknown.count, 2);

        final known = groups.singleWhere(
          (g) => g.journalName == 'Known Journal',
        );
        expect(known.count, 1);
      },
    );

    test('returns an empty list for no publications', () {
      expect(JournalGroup.groupByJournal(const []), isEmpty);
    });
  });
}
