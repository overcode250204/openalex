import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/core/utils/abstract_converter.dart';
import 'package:openalex/mappers/zotero_mapper.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/models/zotero.dart';

void main() {
  group('AbstractConverter', () {
    test('returns null for null or empty inverted index', () {
      expect(AbstractConverter.fromInvertedIndex(null), isNull);
      expect(AbstractConverter.fromInvertedIndex({}), isNull);
    });

    test('rebuilds abstract text by sorted positions', () {
      final text = AbstractConverter.fromInvertedIndex({
        'world': [1],
        'Hello': [0],
        'ignored': ['bad', null],
        'again': [2],
      });

      expect(text, 'Hello world again');
    });
  });

  group('Publication', () {
    test('parses a complete OpenAlex payload', () {
      final publication = Publication.fromJson({
        'id': 'https://openalex.org/W1',
        'display_name': 'Useful Paper',
        'publication_year': 2024,
        'cited_by_count': 42,
        'primary_location': {
          'source': {'display_name': 'Journal of Tests'},
        },
        'doi': 'https://doi.org/10.1000/test',
        'abstract_inverted_index': {
          'Testing': [0],
          'matters': [1],
        },
        'authorships': [
          {
            'author': {'display_name': 'Ada Lovelace'},
          },
          {
            'author': {'display_name': 'Grace Hopper'},
          },
          {'author': {}},
        ],
      });

      expect(publication.id, 'https://openalex.org/W1');
      expect(publication.title, 'Useful Paper');
      expect(publication.publicationYear, 2024);
      expect(publication.citedByCount, 42);
      expect(publication.journalName, 'Journal of Tests');
      expect(publication.doi, 'https://doi.org/10.1000/test');
      expect(publication.abstractText, 'Testing matters');
      expect(publication.authors, ['Ada Lovelace', 'Grace Hopper']);
      expect(publication.displayYear, '2024');
      expect(publication.displayJournal, 'Journal of Tests');
      expect(publication.displayAuthors, 'Ada Lovelace, Grace Hopper');
    });

    test('uses display fallbacks when data is missing', () {
      final publication = Publication.fromJson({});

      expect(publication.id, '');
      expect(publication.title, 'No title');
      expect(publication.publicationYear, isNull);
      expect(publication.citedByCount, 0);
      expect(publication.journalName, isNull);
      expect(publication.doi, isNull);
      expect(publication.abstractText, isNull);
      expect(publication.authors, isEmpty);
      expect(publication.displayYear, 'Unknown year');
      expect(publication.displayJournal, 'Unknown journal');
      expect(publication.displayAuthors, 'Unknown authors');
    });
  });

  group('ZoteroItem', () {
    test('parses Zotero item data and creators', () {
      final item = ZoteroItem.fromJson({
        'key': 'ABC123',
        'data': {
          'title': 'Saved Article',
          'itemType': 'journalArticle',
          'date': '2025',
          'DOI': '10.1000/saved',
          'publicationTitle': 'Saved Journal',
          'creators': [
            {'firstName': 'Alan', 'lastName': 'Turing'},
            {'lastName': 'NoFirstName'},
            {'firstName': '', 'lastName': ''},
          ],
        },
      });

      expect(item.key, 'ABC123');
      expect(item.title, 'Saved Article');
      expect(item.itemType, 'journalArticle');
      expect(item.date, '2025');
      expect(item.doi, '10.1000/saved');
      expect(item.journal, 'Saved Journal');
      expect(item.authors, ['Alan Turing', 'NoFirstName']);
    });

    test('uses fallbacks for malformed Zotero data', () {
      final item = ZoteroItem.fromJson({});

      expect(item.key, '');
      expect(item.title, 'No title');
      expect(item.itemType, '');
      expect(item.authors, isEmpty);
    });
  });

  group('ZoteroMapper', () {
    test('maps a publication to Zotero journal article payload', () {
      final payload = ZoteroMapper.fromPublication(
        Publication(
          id: 'W1',
          title: 'Mapped Paper',
          publicationYear: 2023,
          citedByCount: 7,
          journalName: 'Mapping Journal',
          doi: '10.1000/mapped',
          abstractText: 'A clear abstract.',
          authors: ['Ada Lovelace', 'Plato'],
          referencedWorkIds: ["1", "2"],
          relatedWorkIds: ["1", "2"],
          oaUrl: "123",
        ),
      );

      expect(payload['itemType'], 'journalArticle');
      expect(payload['title'], 'Mapped Paper');
      expect(payload['abstractNote'], 'A clear abstract.');
      expect(payload['publicationTitle'], 'Mapping Journal');
      expect(payload['date'], '2023');
      expect(payload['DOI'], '10.1000/mapped');
      expect(payload['creators'], [
        {'creatorType': 'author', 'firstName': 'Ada', 'lastName': 'Lovelace'},
        {'creatorType': 'author', 'firstName': '', 'lastName': 'Plato'},
      ]);
      expect(payload['tags'], [
        {'tag': 'OpenAlex'},
        {'tag': 'RIPQMS'},
      ]);
    });

    test('removes empty optional fields and empty creator list', () {
      final payload = ZoteroMapper.fromPublication(
        Publication(
          id: 'W2',
          title: 'Minimal Paper',
          publicationYear: null,
          citedByCount: 0,
          journalName: '',
          doi: '',
          abstractText: null,
          authors: [],
          referencedWorkIds: List.empty(),
          relatedWorkIds: List.empty(),
          oaUrl: "",
        ),
      );

      expect(payload, isNot(contains('abstractNote')));
      expect(payload, isNot(contains('publicationTitle')));
      expect(payload, isNot(contains('date')));
      expect(payload, isNot(contains('DOI')));
      expect(payload, isNot(contains('creators')));
      expect(payload['title'], 'Minimal Paper');
    });
  });
}
