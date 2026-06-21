import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openalex/models/topic.dart';
import '../models/journal_suggestion.dart';
import '../models/keyword/openalex_keyword.dart';

class SuggestionService {
  static const String mailto = 'trandinhbao222@gmail.com';

  final http.Client _client;

  SuggestionService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<TopicSuggestion>> fetchTopicSuggestions(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final uri = Uri.https('api.openalex.org', '/topics', {
        'search': query,
        'per-page': '5',
        'select': 'id,display_name,works_count',
        'mailto': mailto,
      });

      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;
      return results
          .map((c) => TopicSuggestion.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> fetchRelatedKeywords(String keyword) async {
    try {
      final uri = Uri.https('api.openalex.org', '/works', {
        'search': keyword,
        'per-page': '10',
        'select': 'concepts',
        'mailto': mailto,
      });

      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final works = data['results'] as List;

      final Map<String, int> conceptCount = {};
      for (final work in works) {
        final concepts = work['concepts'] as List? ?? [];
        for (final c in concepts) {
          final name = c['display_name'] as String? ?? '';
          final score = (c['score'] as num?)?.toDouble() ?? 0;
          if (name.isNotEmpty && score > 0.3 && name != keyword) {
            conceptCount[name] = (conceptCount[name] ?? 0) + 1;
          }
        }
      }

      final sorted = conceptCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(6).map((e) => e.key).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> fetchKeywordSuggestions(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final uri = Uri.https('api.openalex.org', '/keywords', {
        'search': query.trim(),
        'per_page': '6',
        'select': 'id,display_name,works_count',
        'mailto': mailto,
      });

      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results
          .map((item) {
            final keyword = item as Map<String, dynamic>;
            return keyword['display_name']?.toString() ?? '';
          })
          .where((name) => name.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OpenAlexKeyword>> fetchOpenAlexKeywordSuggestions(
    String query,
  ) async {
    if (query.trim().length < 2) return [];

    try {
      final uri = Uri.https('api.openalex.org', '/keywords', {
        'search': query.trim(),
        'per_page': '6',
        'select': 'id,display_name,works_count,cited_by_count',
        'mailto': mailto,
      });

      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results
          .map((item) => OpenAlexKeyword.fromJson(item as Map<String, dynamic>))
          .where((keyword) => keyword.displayName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<JournalSuggestion>> fetchJournalSuggestions(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      return [];
    }

    try {
      final uri = Uri.https('api.openalex.org', '/sources', {
        'search': trimmedQuery,
        'filter': 'type:journal',
        'per-page': '6',
        'select':
            'id,display_name,works_count,issn_l,host_organization_name,type',
        'mailto': mailto,
      });

      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;

      final List<dynamic> results = body['results'] as List<dynamic>? ?? [];

      return results
          .map(
            (item) => JournalSuggestion.fromJson(item as Map<String, dynamic>),
          )
          .where((journal) => journal.displayName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
