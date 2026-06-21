import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_source.dart';

void main() {
  group('JournalSource.fromJson', () {
    test('parses a complete OpenAlex source payload', () {
      final source = JournalSource.fromJson({
        'id': 'https://openalex.org/S2770115547',
        'display_name': 'IEEE Access',
        'type': 'journal',
        'issn_l': '2169-3536',
        'issn': ['2169-3536', '2169-3544'],
        'works_count': 78000,
        'cited_by_count': 900000,
        'summary_stats': {'h_index': 84},
        'host_organization_name':
            'Institute of Electrical and Electronics Engineers',
      });

      expect(source.id, 'https://openalex.org/S2770115547');
      expect(source.sourceId, 'S2770115547');
      expect(source.displayName, 'IEEE Access');
      expect(source.type, 'journal');
      expect(source.issnL, '2169-3536');
      expect(source.issn, ['2169-3536', '2169-3544']);
      expect(source.worksCount, 78000);
      expect(source.citedByCount, 900000);
      expect(source.hIndex, 84);
      expect(
        source.hostOrganizationName,
        'Institute of Electrical and Electronics Engineers',
      );
    });

    test('applies default fallbacks for missing fields', () {
      final source = JournalSource.fromJson({});

      expect(source.id, '');
      expect(source.sourceId, '');
      expect(source.displayName, 'Unknown journal');
      expect(source.type, '');
      expect(source.issnL, isNull);
      expect(source.issn, isEmpty);
      expect(source.worksCount, 0);
      expect(source.citedByCount, 0);
      expect(source.hIndex, isNull);
      expect(source.hostOrganizationName, isNull);
    });

    test('handles null summary_stats gracefully', () {
      final source = JournalSource.fromJson({
        'id': 'https://openalex.org/S1',
        'summary_stats': null,
      });

      expect(source.hIndex, isNull);
    });

    test('filters out null issn values', () {
      final source = JournalSource.fromJson({
        'id': 'https://openalex.org/S1',
        'issn': [null, '1234-5678', null],
      });

      expect(source.issn, ['1234-5678']);
    });

    test('extracts sourceId from URL path correctly', () {
      final source = JournalSource.fromJson({
        'id': 'https://openalex.org/S9876543210',
      });

      expect(source.sourceId, 'S9876543210');
    });
  });

  group('JournalSource.displayIssnL', () {
    test('returns issnL when present and non-empty', () {
      final source = JournalSource.fromJson({
        'id': 'https://openalex.org/S1',
        'issn_l': '2169-3536',
      });

      expect(source.displayIssnL, '2169-3536');
    });

    test('returns N/A when issnL is null', () {
      final source = JournalSource.fromJson({'id': 'https://openalex.org/S1'});

      expect(source.displayIssnL, 'N/A');
    });

    test('returns N/A when issnL is whitespace only', () {
      final source = JournalSource(
        id: 'S1',
        sourceId: 'S1',
        displayName: 'Journal',
        type: 'journal',
        issnL: '   ',
        issn: [],
        worksCount: 0,
        citedByCount: 0,
        hIndex: null,
        hostOrganizationName: null,
      );

      expect(source.displayIssnL, 'N/A');
    });
  });

  group('JournalSource.displayPublisher', () {
    test('returns publisher name when hostOrganizationName is present', () {
      final source = JournalSource.fromJson({
        'id': 'https://openalex.org/S1',
        'host_organization_name': 'Elsevier',
      });

      expect(source.displayPublisher, 'Elsevier');
    });

    test('returns Unknown publisher when hostOrganizationName is null', () {
      final source = JournalSource.fromJson({'id': 'https://openalex.org/S1'});

      expect(source.displayPublisher, 'Unknown publisher');
    });

    test(
      'returns Unknown publisher when hostOrganizationName is whitespace',
      () {
        final source = JournalSource(
          id: 'S1',
          sourceId: 'S1',
          displayName: 'Journal',
          type: 'journal',
          issnL: null,
          issn: [],
          worksCount: 0,
          citedByCount: 0,
          hIndex: null,
          hostOrganizationName: '   ',
        );

        expect(source.displayPublisher, 'Unknown publisher');
      },
    );
  });
}
