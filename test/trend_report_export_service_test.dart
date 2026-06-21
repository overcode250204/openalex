import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/services/trend_report_export_service.dart';

class FakeOpenAlexService extends OpenAlexService {
  FakeOpenAlexService(this.results, {required this.total});

  final List<Publication> results;
  final int total;

  @override
  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async {
    return (total, results);
  }
}

class FakeSearchHistoryService extends SearchHistoryService {
  @override
  Future<void> addHistory(String keyword) async {}

  @override
  Future<List<String>> getHistory() async {
    return [];
  }
}

class FakeSuggestionService extends SuggestionService {
  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async {
    return [];
  }
}

PublicationProvider testProvider(OpenAlexService service) {
  return PublicationProvider(
    service,
    historyService: FakeSearchHistoryService(),
    suggestionService: FakeSuggestionService(),
  );
}

Publication publication({
  required String title,
  required int citations,
  required int year,
  required String journal,
  required List<String> authors,
}) {
  return Publication(
    id: title,
    title: title,
    publicationYear: year,
    citedByCount: citations,
    journalName: journal,
    doi: null,
    abstractText: null,
    authors: authors,
    referencedWorkIds: ["1", "2"],
    relatedWorkIds: ["1", "2"],
    oaUrl: "123",
  );
}

void main() {
  test('builds a markdown trend report from provider analytics', () async {
    final provider = testProvider(
      FakeOpenAlexService([
        publication(
          title: 'High Impact Paper',
          citations: 50,
          year: 2023,
          journal: 'Journal A',
          authors: ['Ada Lovelace'],
        ),
        publication(
          title: 'Recent Paper',
          citations: 10,
          year: 2024,
          journal: 'Journal A',
          authors: ['Ada Lovelace', 'Grace Hopper'],
        ),
      ], total: 2),
    );
    await provider.searchPublications(keyword: 'Artificial Intelligence');

    final report = const TrendReportExportService().buildMarkdownReport(
      provider.trendReportSnapshot,
      generatedAt: DateTime(2026, 6, 13, 10, 30, 45),
    );

    expect(report, contains('# Journal Trend Analyzer Report'));
    expect(report, contains('Topic: Artificial Intelligence'));
    expect(report, contains('Generated at: 2026-06-13 10:30:45'));
    expect(report, contains('| 2023 | 1 |'));
    expect(report, contains('| 2024 | 1 |'));
    expect(
      report,
      contains('| 1 | High Impact Paper | 2023 | Journal A | 50 |'),
    );
    expect(report, contains('| 1 | Journal A | 2 papers |'));
    expect(report, contains('| 1 | Ada Lovelace | 2 papers |'));
    expect(report, contains('The publication trend is stable'));
  });

  test('cleans exported report values for presentation quality', () async {
    final provider = testProvider(
      FakeOpenAlexService([
        publication(
          title: '',
          citations: 50,
          year: 2023,
          journal: 'Unknown journal',
          authors: ['Ada Lovelace'],
        ),
        publication(
          title: 'Encoding Paper',
          citations: 10,
          year: 2024,
          journal: 'DROPS (Schloss Dagstuhl â€“ Leibniz Center)',
          authors: ['Grace Hopper'],
        ),
      ], total: 2),
    );
    await provider.searchPublications(keyword: 'Artificial Intelligence');

    final report = const TrendReportExportService().buildMarkdownReport(
      provider.trendReportSnapshot,
      generatedAt: DateTime(2026, 6, 13, 10, 30, 45),
    );

    expect(report, contains('Top journal: DROPS'));
    expect(report, contains('Untitled publication'));
    expect(report, contains('Schloss Dagstuhl - Leibniz Center'));
    expect(report, isNot(contains('â€“')));
  });
}
