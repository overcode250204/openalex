import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:openalex/models/search_filter.dart';
import 'package:openalex/services/analytics_service.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late MockClient mockClient;
  late AnalyticsService service;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockClient = MockClient();
    service = AnalyticsService(client: mockClient);
  });

  test('fetchAll returns AnalyticsResult on success', () async {
    when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(
          jsonEncode({
            'meta': {'count': 100},
            'results': [
              {'display_name': 'Test Paper', 'cited_by_count': 50}
            ],
            'group_by': [
              {'key': '2023', 'key_display_name': '2023', 'count': 10},
              {'key': '2022', 'key_display_name': '2022', 'count': 20},
            ]
          }),
          200,
        ));

    final result = await service.fetchAll('test', const SearchFilter());

    expect(result, isA<AnalyticsResult>());
    expect(result.totalWorks, 100);
    expect(result.mostCitedTitle, 'Test Paper');
    expect(result.mostCitedCount, 50);
    expect(result.publicationTrend, isNotEmpty);
  });

  test('fetchAll handles empty results', () async {
    when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(
          jsonEncode({
            'meta': {'count': 0},
            'results': [],
            'group_by': []
          }),
          200,
        ));

    final result = await service.fetchAll('test', const SearchFilter());

    expect(result, isA<AnalyticsResult>());
    expect(result.totalWorks, 0);
    expect(result.mostCitedTitle, isNull);
    expect(result.publicationTrend, isEmpty);
  });

  test('fetchAll handles non-200 response', () async {
    when(() => mockClient.get(any()))
        .thenAnswer((_) async => http.Response('Error', 500));

    final result = await service.fetchAll('test', const SearchFilter());

    expect(result, isA<AnalyticsResult>());
    expect(result.totalWorks, 0);
    expect(result.publicationTrend, isEmpty);
  });

  test('fetchAll throws when client throws exception', () async {
    final client = MockClient();
    final service = AnalyticsService(client: client);

    when(() => client.get(any())).thenThrow(Exception('Network Error'));

    await expectLater(
      service.fetchAll('test', const SearchFilter()),
      throwsException,
    );
  });
  
  test('fetchAll query params check', () async {
    when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(
          jsonEncode({
            'meta': {'count': 0},
            'results': [],
            'group_by': []
          }),
          200,
        ));

    await service.fetchAll('test', const SearchFilter(yearFrom: 2020));
    
    // verify the client was called
    verify(() => mockClient.get(any())).called(greaterThan(0));
  });
}
