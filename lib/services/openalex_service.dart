import 'dart:convert';

import 'package:http/http.dart' as http;


import '../models/publication.dart';

class OpenAlexService {
  static const String _baseUrl = 'https://api.openalex.org';
  final http.Client _client;

  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    int page = 1,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return (0, <Publication>[]);
    }

    final Map<String, String> queryParameters = {
      'search': trimmedKeyword,
      'per-page': perPage.toString(),
      'page': page.toString(),
      'sort': sort,
      'mailto' : "truongtuan20042004@gmail.com"
    };

    final filters = <String>[];

     if (topicIds != null && topicIds.isNotEmpty) {
    filters.add(
      'primary_topic.id:${topicIds.join('|')}',
    );
  }

    queryParameters['filter'] = filters.join(',');
   

    final uri = Uri.https('api.openalex.org', '/works', queryParameters);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }
    

    final Map<String, dynamic> body = jsonDecode(response.body);
    final int total = (body['meta']?['count'] as num? ?? 0).toInt();
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];
     return (total, results
        .map((item) => Publication.fromJson(item as Map<String, dynamic>))
        .toList());
  }

  Future<(int total, List<Publication> publications)> searchWithFilter(Map<String,String> params) async {

    
    final uri = Uri.https('api.openalex.org', '/works', params);
    print(uri);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final results = body['results'] as List<dynamic>? ?? [];
    final int totalResult = body['meta']['count'] ?? 0;
    
    return (totalResult, results
        .map((item) => Publication.fromJson(item as Map<String, dynamic>))
        .toList());
  }



Future<List<String>> getTopicIdsFromKeyword(String keyword) async {
  final uri = Uri.https(
    'api.openalex.org',
    '/topics',
    {
      'search': keyword,
      'per-page': '3',
      'mailto': 'truongtuan20042004@gmail.com',
    },
  );

  final response = await _client.get(uri);

  if (response.statusCode != 200) {
    return [];
  }

  final body = jsonDecode(response.body);
  final topics = body['results'] as List? ?? [];

  if (topics.isEmpty) {
    return [];
  }

  final exactMatch = topics.cast<Map<String, dynamic>?>().firstWhere(
    (topic) =>
        topic?['display_name']
                ?.toString()
                .toLowerCase() ==
            keyword.toLowerCase(),
    orElse: () => null,
  );

  if (exactMatch != null) {
    return [
      exactMatch['id']
          .toString()
          .split('/')
          .last,
    ];
  }

  return topics
      .take(3)
      .map<String>(
        (topic) => topic['id']
            .toString()
            .split('/')
            .last,
      )
      .toList();
}

  //Get detail by Work Id
 Future<Publication?> fetchDetail(String workId) async {
    try {
      final id = _normalizeId(workId);
      print(id);
      final uri = Uri.https('api.openalex.org', '/works/$id', {'mailto': "truongtuan20042004@gmail.com"});
       print(uri);
      final res = await http.get(uri);
     
      print(res.body);
      if (res.statusCode != 200) {
        print(res.body);
      throw Exception(
        'OpenAlex request failed with status code ${res.statusCode}',
      );
      }
      return Publication.fromJson(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }
   
   
 static const _briefSelect =
      'id,doi,display_name,publication_year,cited_by_count,'
      'primary_location,best_oa_location,open_access,'
      'authorships,related_works,referenced_works'
      ;
// Get Work by Mutiple Id
Future<List<Publication>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final batch = ids.take(10).map(_normalizeId).join('|');
      final uri = Uri.https('api.openalex.org', '/works', {
        'filter': 'ids.openalex:$batch',
        'select': _briefSelect,
        'per-page': '20',
        'mailto': "truongtuan20042004@gmail.com",
      });
      print(uri);
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      return (data['results'] as List)
          .map((j) => Publication.fromJsonBrief(j))
          .toList();
    } catch (_) {
      return [];
    }
}

//Get Work cited Current work
Future<List<Publication>> fetchCitedBy(
      String workId, {int page = 1}) async {
    try {
      final id = _normalizeId(workId);
      final uri = Uri.https('api.openalex.org', '/works', {
        'filter': 'cites:$id',
        'select': _briefSelect,
        'sort': 'cited_by_count:desc',
        'per-page': '20',
        'page': '$page',
        'mailto': "truongtuan@gmail.com",
      });
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      return (data['results'] as List)
          .map((j) => Publication.fromJsonBrief(j))
          .toList();
    } catch(_){
      return [];
    }
  }
  String _normalizeId(String id) {
    return id.replaceAll('https://openalex.org/', '');
  }

  Future<List<Publication>> fetchInfluentialPapers({
    required String keyword,
    int? limit,
  }) async {
    final queryParams = {
      'search': keyword,
      'sort': 'cited_by_count:desc',
      'per-page': limit == null ? '200' : limit.toString(),
      'mailto': 'truongtuan20042004@gmail.com'
    };

    final uri = Uri.https('api.openalex.org', '/works', queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load influential papers');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];

    return results.map((item) => Publication.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, int>> fetchTopResearchJournals({
    required String keyword,
    int? limit,
  }) async {
    final queryParams = {
      'search': keyword,
      'sort': 'cited_by_count:desc',
      'per-page': '200',
      'mailto': 'truongtuan20042004@gmail.com'
    };

    final uri = Uri.https('api.openalex.org', '/works', queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load top research journals');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];

    final Map<String, int> journals = {};
    for (final work in results) {
      final journalName = work['primary_location']?['source']?['display_name'] ?? 'Unknown Journal';
      journals[journalName] = (journals[journalName] ?? 0) + 1;
    }

    final sortedEntries = journals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final selectedEntries = limit == null
        ? sortedEntries
        : sortedEntries.take(limit).toList();
        
    return Map.fromEntries(selectedEntries);
  }

  Future<Map<String, int>> fetchTopContributingAuthors({
    required String keyword,
    int? limit,
  }) async {
    final queryParams = {
      'search': keyword,
      'sort': 'cited_by_count:desc',
      'per-page': '200',
      'mailto': 'truongtuan20042004@gmail.com'
    };

    final uri = Uri.https('api.openalex.org', '/works', queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load top contributing authors');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];

    final Map<String, int> authors = {};
    for (final work in results) {
      final authorships = work['authorships'] as List<dynamic>? ?? [];
      for (final authorship in authorships) {
        final name = authorship['author']?['display_name'];
        if (name != null) {
          authors[name] = (authors[name] ?? 0) + 1;
        }
      }
    }

    final sortedEntries = authors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final selectedEntries = limit == null
        ? sortedEntries
        : sortedEntries.take(limit).toList();
        
    return Map.fromEntries(selectedEntries);
  }
}
