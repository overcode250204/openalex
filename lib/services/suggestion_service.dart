import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openalex/models/topic.dart';

class SuggestionService {

  Future<List<TopicSuggestion>> fetchTopicSuggestions(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final uri = Uri.https('api.openalex.org', '/topics', {
        'search': query,
        'per-page': '5',
        'select': 'id,display_name,works_count',
        'mailto': 'truongtuan20042004@gmail.com',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;
      return results.map((c) => TopicSuggestion.fromJson(c as Map<String, dynamic>)).toList();
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
        'mailto': 'your_email@example.com',
      });

      final response = await http.get(uri);
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
}