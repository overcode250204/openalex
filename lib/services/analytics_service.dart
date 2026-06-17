import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_filter.dart';

class AnalyticsResult {
  final Map<int, int> publicationTrend;
  final Map<String, int> topKeywords;
  final Map<String, int> institutionRanking;
  final Map<String, int> countryOutput;

  const AnalyticsResult({
    required this.publicationTrend,
    required this.topKeywords,
    required this.institutionRanking,
    required this.countryOutput,
  });

  static AnalyticsResult empty() => const AnalyticsResult(
        publicationTrend: {},
        topKeywords: {},
        institutionRanking: {},
        countryOutput: {},
      );
}

class AnalyticsService {
  final http.Client _client;

  AnalyticsService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, int>> _fetchGroupBy(
    Map<String, String> baseParams,
    String groupByField,
  ) async {
    final params = <String, String>{
      if (baseParams.containsKey('search')) 'search': baseParams['search']!,
      if (baseParams.containsKey('filter')) 'filter': baseParams['filter']!,
      if (baseParams.containsKey('mailto')) 'mailto': baseParams['mailto']!,
      'group_by': groupByField,
    };

    final uri = Uri.https('api.openalex.org', '/works', params);
    final response = await _client.get(uri);

    if (response.statusCode != 200) return {};

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final groups = body['group_by'] as List<dynamic>? ?? [];

    return Map.fromEntries(
      groups.map((g) {
        // key_display_name is always the human-readable label for all group_by fields
        final displayName = g['key_display_name']?.toString() ?? g['key']?.toString() ?? '';
        return MapEntry(displayName, (g['count'] as num? ?? 0).toInt());
      }).where((e) => e.key.isNotEmpty),
    );
  }

  Future<AnalyticsResult> fetchAll(
    String keyword,
    SearchFilter filter,
  ) async {
    final baseParams = filter.toQueryParams(keyword, []);

    final results = await Future.wait([
      _fetchGroupBy(baseParams, 'publication_year'),
      _fetchGroupBy(baseParams, 'concepts.id'),
      _fetchGroupBy(baseParams, 'authorships.institutions.id'),
      _fetchGroupBy(baseParams, 'authorships.countries'),
    ]);

    // Convert year string keys → Map<int, int>, filter to last 35 years, sort ascending
    final currentYear = DateTime.now().year;
    final cutoffYear = currentYear - 35;
    final publicationTrend = <int, int>{};
    for (final entry in results[0].entries) {
      final year = int.tryParse(entry.key);
      if (year != null && year >= cutoffYear) {
        publicationTrend[year] = entry.value;
      }
    }
    final sortedTrend = Map.fromEntries(
      publicationTrend.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return AnalyticsResult(
      publicationTrend: sortedTrend,
      topKeywords: results[1],
      institutionRanking: results[2],
      countryOutput: results[3],
    );
  }
}
