import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/zotero_serivce.dart';

void main() {
  group('OpenAlexService', () {
    test(
      'returns empty results for blank keywords without calling HTTP',
      () async {
        var called = false;
        final service = OpenAlexService(
          client: MockClient((request) async {
            called = true;
            return http.Response('{}', 200);
          }),
        );

        final results = await service.searchPublications(keyword: '   ');

        expect(results, isEmpty);
        expect(called, isFalse);
      },
    );

    test('builds query parameters and parses publication results', () async {
      Uri? requestedUri;
      final service = OpenAlexService(
        client: MockClient((request) async {
          requestedUri = request.url;

          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'W1',
                  'display_name': 'Network Paper',
                  'publication_year': 2024,
                  'cited_by_count': 8,
                },
              ],
            }),
            200,
          );
        }),
      );

      final results = await service.searchPublications(
        keyword: '  machine learning  ',
        perPage: 25,
        sort: 'publication_year:desc',
        fromYear: 2020,
        toYear: 2024,
      );

      expect(requestedUri.toString(), contains('/works'));
      expect(requestedUri?.queryParameters['search'], 'machine learning');
      expect(requestedUri?.queryParameters['per-page'], '25');
      expect(requestedUri?.queryParameters['sort'], 'publication_year:desc');
      expect(
        requestedUri?.queryParameters['filter'],
        'from_publication_date:2020-01-01,to_publication_date:2024-12-31',
      );
      expect(results.single.title, 'Network Paper');
      expect(results.single.publicationYear, 2024);
      expect(results.single.citedByCount, 8);
    });

    test('supports one-sided year filters and empty result payloads', () async {
      final requestedUris = <Uri>[];
      final service = OpenAlexService(
        client: MockClient((request) async {
          requestedUris.add(request.url);
          return http.Response(jsonEncode({}), 200);
        }),
      );

      final fromResults = await service.searchPublications(
        keyword: 'AI',
        fromYear: 2021,
      );
      final toResults = await service.searchPublications(
        keyword: 'AI',
        toYear: 2022,
      );

      expect(fromResults, isEmpty);
      expect(toResults, isEmpty);
      expect(
        requestedUris.first.queryParameters['filter'],
        'from_publication_date:2021-01-01',
      );
      expect(
        requestedUris.last.queryParameters['filter'],
        'to_publication_date:2022-12-31',
      );
    });

    test('throws when OpenAlex responds with an error status', () {
      final service = OpenAlexService(
        client: MockClient((request) async => http.Response('nope', 500)),
      );

      expect(
        () => service.searchPublications(keyword: 'AI'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ZoteroService', () {
    test(
      'fails fast when credentials are missing without calling HTTP',
      () async {
        dotenv.testLoad(fileInput: '');
        var called = false;
        final service = ZoteroService(
          client: MockClient((request) async {
            called = true;
            return http.Response('{}', 200);
          }),
        );

        await expectLater(
          () => service.savePublicationToZotero(samplePublication()),
          throwsA(isA<Exception>()),
        );
        expect(called, isFalse);
      },
    );

    test('posts mapped publication and returns Zotero key', () async {
      Map<String, String>? headers;
      Object? decodedBody;
      Uri? requestedUri;
      final service = ZoteroService(
        apiKey: 'secret',
        userId: 'user-1',
        client: MockClient((request) async {
          requestedUri = request.url;
          headers = request.headers;
          decodedBody = jsonDecode(request.body);

          return http.Response(
            jsonEncode({
              'successful': {
                '0': {'key': 'ZOT123'},
              },
            }),
            201,
          );
        }),
      );

      final key = await service.savePublicationToZotero(samplePublication());

      expect(
        requestedUri.toString(),
        'https://api.zotero.org/users/user-1/items',
      );
      expect(headers?['Content-Type'], 'application/json');
      expect(headers?['Zotero-API-Key'], 'secret');
      expect(headers?['Zotero-API-Version'], '3');
      expect(decodedBody, isA<List<dynamic>>());
      expect((decodedBody as List<dynamic>).single['title'], 'Paper');
      expect(key, 'ZOT123');
    });

    test('throws for Zotero error response and missing returned key', () async {
      final errorService = ZoteroService(
        apiKey: 'secret',
        userId: 'user-1',
        client: MockClient((request) async => http.Response('bad', 400)),
      );
      final missingKeyService = ZoteroService(
        apiKey: 'secret',
        userId: 'user-1',
        client: MockClient(
          (request) async => http.Response(jsonEncode({'successful': {}}), 200),
        ),
      );

      await expectLater(
        () => errorService.savePublicationToZotero(samplePublication()),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        () => missingKeyService.savePublicationToZotero(samplePublication()),
        throwsA(isA<Exception>()),
      );
    });
  });
}

Publication samplePublication() {
  return Publication(
    id: 'W1',
    title: 'Paper',
    publicationYear: 2024,
    citedByCount: 0,
    journalName: 'Journal',
    doi: '10.1000/paper',
    abstractText: 'Abstract',
    authors: const ['Ada Lovelace'],
  );
}
