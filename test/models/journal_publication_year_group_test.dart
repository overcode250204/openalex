import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_publication.dart';
import 'package:openalex/models/journal/journal_publication_year_group.dart';

JournalPublication _publication({required String id, int? year}) {
  return JournalPublication(
    id: id,
    workId: id,
    title: id,
    publicationYear: year,
    publicationDate: null,
    doi: null,
    citedByCount: 0,
    authors: const [],
    journalName: null,
    sourceId: null,
    isOpenAccess: false,
    landingPageUrl: null,
    pdfUrl: null,
    abstractText: null,
  );
}

void main() {
  group('JournalPublicationYearGroup.groupByYear', () {
    test('ranks years from highest to lowest publication count', () {
      final groups = JournalPublicationYearGroup.groupByYear([
        _publication(id: 'A1', year: 2024),
        _publication(id: 'B1', year: 2023),
        _publication(id: 'A2', year: 2024),
        _publication(id: 'A3', year: 2024),
        _publication(id: 'B2', year: 2023),
      ]);

      expect(groups.map((g) => g.year).toList(), [2024, 2023]);
      expect(groups.map((g) => g.count).toList(), [3, 2]);
    });

    test('breaks ties by most recent year first', () {
      final groups = JournalPublicationYearGroup.groupByYear([
        _publication(id: 'P1', year: 2021),
        _publication(id: 'P2', year: 2023),
      ]);

      expect(groups.map((g) => g.year).toList(), [2023, 2021]);
    });

    test('buckets publications with missing publication year safely', () {
      final groups = JournalPublicationYearGroup.groupByYear([
        _publication(id: 'P1', year: null),
        _publication(id: 'P2', year: null),
        _publication(id: 'P3', year: 2024),
      ]);

      final unknown = groups.singleWhere((g) => g.year == null);
      expect(unknown.count, 2);
      expect(unknown.displayYear, 'Unknown year');

      final known = groups.singleWhere((g) => g.year == 2024);
      expect(known.count, 1);
      expect(known.displayYear, '2024');
    });

    test('returns an empty list for no publications', () {
      expect(JournalPublicationYearGroup.groupByYear(const []), isEmpty);
    });
  });
}
