import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:openalex/models/publication.dart';
import 'package:openalex/mappers/zotero_mapper.dart';

class ZoteroService {
  final String apiKey;
  final String userId;
  final http.Client _client;

  ZoteroService({String? apiKey, String? userId, http.Client? client})
    : apiKey = apiKey ?? dotenv.env['ZOTERO_API_KEY'] ?? '',
      userId = userId ?? dotenv.env['ZOTERO_USER_ID'] ?? '',
      _client = client ?? http.Client();

  Future<String> savePublicationToZotero(Publication publication) async {
    if (apiKey.isEmpty || userId.isEmpty) {
      throw Exception('Missing Zotero API key or user ID');
    }

    final zoteroItem = ZoteroMapper.fromPublication(publication);

    final response = await _client.post(
      Uri.parse('https://api.zotero.org/users/$userId/items'),
      headers: {
        'Content-Type': 'application/json',
        'Zotero-API-Key': apiKey,
        'Zotero-API-Version': '3',
      },
      body: jsonEncode([zoteroItem]),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to save to Zotero: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    final key = body['successful']?['0']?['key']?.toString();

    if (key == null || key.isEmpty) {
      throw Exception('Zotero saved item but key was not returned');
    }

    return key;
  }
}
