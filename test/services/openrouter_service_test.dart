import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:openalex/models/ai/ai_chat_message.dart';
import 'package:openalex/models/ai/publication_ai_context.dart';
import 'package:openalex/services/ai/openrouter_service.dart';

void main() {
  group('OpenRouterService', () {
    test('sends publication context and parses sanitized answer', () async {
      final client = _RecordingClient(
        response: http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'Final answer: This paper studies AI.'},
              },
            ],
          }),
          200,
        ),
      );
      final service = OpenRouterService(
        client: client,
        apiKey: 'test-key',
        model: 'openrouter/free',
      );

      final answer = await service.askPublication(
        context: _context(),
        recentMessages: [
          AiChatMessage(
            role: AiChatRole.user,
            content: 'Summarize it',
            createdAt: DateTime(2026),
          ),
        ],
        userMessage: 'What is the research gap?',
      );

      expect(answer, 'This paper studies AI.');
      expect(client.lastRequest?.headers['Authorization'], 'Bearer test-key');
      final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(body['model'], 'openrouter/free');
      final messages = body['messages'] as List<dynamic>;
      expect(messages.first['role'], 'system');
      expect(
        messages.any(
          (message) => message['content'].toString().contains('AI in Medicine'),
        ),
        isTrue,
      );
      expect(messages.last['content'], 'What is the research gap?');
    });

    test('throws a friendly error when api key is missing', () async {
      final service = OpenRouterService(
        client: _RecordingClient(response: http.Response('{}', 200)),
        apiKey: '',
      );

      await expectLater(
        service.askPublication(
          context: _context(),
          recentMessages: const [],
          userMessage: 'Hello',
        ),
        throwsA(
          isA<OpenRouterException>().having(
            (error) => error.message,
            'message',
            contains('Missing OpenRouter API key'),
          ),
        ),
      );
    });

    test('maps rate limit responses to friendly errors', () async {
      final service = OpenRouterService(
        client: _RecordingClient(response: http.Response('{}', 429)),
        apiKey: 'test-key',
      );

      await expectLater(
        service.askPublication(
          context: _context(),
          recentMessages: const [],
          userMessage: 'Hello',
        ),
        throwsA(
          isA<OpenRouterException>().having(
            (error) => error.message,
            'message',
            contains('rate limit'),
          ),
        ),
      );
    });
  });
}

PublicationAiContext _context() {
  return const PublicationAiContext(
    title: 'AI in Medicine',
    authors: 'Ada Lovelace',
    journal: 'Journal of AI',
    year: '2026',
    citationCount: '42',
    doi: 'https://doi.org/10.1/test',
    openAccessUrl: 'https://example.com/paper.pdf',
    abstractText: 'This paper studies AI in clinical decision support.',
  );
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient({required this.response});

  final http.Response response;
  http.BaseRequest? lastRequest;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    if (request is http.Request) {
      lastBody = request.body;
    }

    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
