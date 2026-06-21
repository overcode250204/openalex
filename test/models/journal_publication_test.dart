import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_publication.dart';

void main() {
  group('JournalPublication.fromJson', () {
    test('parses a complete OpenAlex work payload', () {
      final publication = JournalPublication.fromJson({
        'id': 'https://openalex.org/W123',
        'display_name': 'Complete Journal Paper',
        'publication_year': 2024,
        'publication_date': '2024-06-01',
        'doi': 'https://doi.org/10.1000/test',
        'cited_by_count': 42,
        'authorships': [
          {
            'author': {'display_name': 'Ada Lovelace'},
          },
          {
            'author': {'display_name': 'Grace Hopper'},
          },
          {'author': {}}, // null display_name — should be filtered
        ],
        'primary_location': {
          'landing_page_url': 'https://example.org/paper',
          'pdf_url': 'https://example.org/paper.pdf',
          'source': {
            'id': 'https://openalex.org/S2770115547',
            'display_name': 'IEEE Access',
          },
        },
        'open_access': {'is_oa': true},
        'abstract_inverted_index': {
          'Research': [0],
          'matters': [1],
        },
      });

      expect(publication.id, 'https://openalex.org/W123');
      expect(publication.workId, 'W123');
      expect(publication.title, 'Complete Journal Paper');
      expect(publication.publicationYear, 2024);
      expect(publication.publicationDate, '2024-06-01');
      expect(publication.doi, 'https://doi.org/10.1000/test');
      expect(publication.citedByCount, 42);
      expect(publication.authors, ['Ada Lovelace', 'Grace Hopper']);
      expect(publication.journalName, 'IEEE Access');
      expect(publication.sourceId, 'S2770115547');
      expect(publication.isOpenAccess, isTrue);
      expect(publication.landingPageUrl, 'https://example.org/paper');
      expect(publication.pdfUrl, 'https://example.org/paper.pdf');
      expect(publication.abstractText, 'Research matters');
    });

    test('applies fallbacks for minimal/missing payload', () {
      final publication = JournalPublication.fromJson({});

      expect(publication.id, '');
      expect(publication.workId, '');
      expect(publication.title, 'Untitled');
      expect(publication.publicationYear, isNull);
      expect(publication.publicationDate, isNull);
      expect(publication.doi, isNull);
      expect(publication.citedByCount, 0);
      expect(publication.authors, isEmpty);
      expect(publication.journalName, isNull);
      expect(publication.sourceId, isNull);
      expect(publication.isOpenAccess, isFalse);
      expect(publication.landingPageUrl, isNull);
      expect(publication.pdfUrl, isNull);
      expect(publication.abstractText, isNull);
    });

    test('prefers display_name over title field', () {
      final fromDisplayName = JournalPublication.fromJson({
        'id': 'W1',
        'display_name': 'Display Name Title',
        'title': 'Title Field',
      });

      expect(fromDisplayName.title, 'Display Name Title');
    });

    test('falls back to title field when display_name is missing', () {
      final publication = JournalPublication.fromJson({
        'id': 'W1',
        'title': 'Title Field Only',
      });

      expect(publication.title, 'Title Field Only');
    });

    test('uses best_oa_location pdf_url when primary pdf_url is absent', () {
      final publication = JournalPublication.fromJson({
        'id': 'W1',
        'display_name': 'OA Paper',
        'primary_location': {'landing_page_url': 'https://landing.com'},
        'best_oa_location': {'pdf_url': 'https://best.com/oa.pdf'},
        'open_access': {'oa_url': 'https://oa.com/paper.pdf'},
      });

      expect(publication.pdfUrl, 'https://best.com/oa.pdf');
    });

    test(
      'sets abstractText to null when abstract_inverted_index is not a map',
      () {
        final publication = JournalPublication.fromJson({
          'id': 'W1',
          'display_name': 'Paper',
          'abstract_inverted_index': 'not a map',
        });

        expect(publication.abstractText, isNull);
      },
    );

    test('extracts sourceId from URL correctly', () {
      final publication = JournalPublication.fromJson({
        'id': 'W1',
        'display_name': 'Paper',
        'primary_location': {
          'source': {'id': 'https://openalex.org/S9876543210'},
        },
      });

      expect(publication.sourceId, 'S9876543210');
    });
  });

  group('JournalPublication display getters', () {
    late JournalPublication full;
    late JournalPublication empty;

    setUp(() {
      full = JournalPublication.fromJson({
        'id': 'https://openalex.org/W1',
        'display_name': 'Full Paper',
        'publication_year': 2024,
        'publication_date': '2024-03-15',
        'doi': '10.1000/full',
        'cited_by_count': 5,
        'authorships': [
          {
            'author': {'display_name': 'Ada Lovelace'},
          },
        ],
        'primary_location': {
          'source': {'display_name': 'Nature'},
        },
      });

      empty = JournalPublication.fromJson({
        'id': 'W2',
        'display_name': 'Empty',
      });
    });

    test('displayYear returns year string or fallback', () {
      expect(full.displayYear, '2024');
      expect(empty.displayYear, 'Unknown year');
    });

    test('displayDate prefers publicationDate over displayYear', () {
      expect(full.displayDate, '2024-03-15');
      expect(empty.displayDate, 'Unknown year');
    });

    test('displayDoi returns doi or No DOI available', () {
      expect(full.displayDoi, '10.1000/full');
      expect(empty.displayDoi, 'No DOI available');
    });

    test('displayJournal returns journalName or Unknown journal', () {
      expect(full.displayJournal, 'Nature');
      expect(empty.displayJournal, 'Unknown journal');
    });

    test('displayAuthors returns joined names or Unknown authors', () {
      expect(full.displayAuthors, 'Ada Lovelace');
      expect(empty.displayAuthors, 'Unknown authors');
    });

    test('displayAuthors joins multiple authors with comma', () {
      final multi = JournalPublication.fromJson({
        'id': 'W3',
        'display_name': 'Multi Author',
        'authorships': [
          {
            'author': {'display_name': 'Ada'},
          },
          {
            'author': {'display_name': 'Grace'},
          },
        ],
      });

      expect(multi.displayAuthors, 'Ada, Grace');
    });

    test('displayDoi returns No DOI available for whitespace doi', () {
      // Whitespace-only DOI is treated as present but not empty by trimming
      final pub = JournalPublication(
        id: 'W4',
        workId: 'W4',
        title: 'Paper',
        publicationYear: null,
        publicationDate: null,
        doi: '   ',
        citedByCount: 0,
        authors: [],
        journalName: null,
        sourceId: null,
        isOpenAccess: false,
        landingPageUrl: null,
        pdfUrl: null,
        abstractText: null,
      );

      // doi is non-null but whitespace → displayDoi should show 'No DOI available'
      expect(pub.displayDoi, 'No DOI available');
    });
  });
}
