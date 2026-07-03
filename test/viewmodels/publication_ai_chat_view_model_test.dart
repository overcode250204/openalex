import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:openalex/models/ai/ai_chat_message.dart';
import 'package:openalex/models/ai/publication_ai_context.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/services/ai/openrouter_service.dart';
import 'package:openalex/viewmodels/publication_ai_chat_view_model.dart';

void main() {
  group('PublicationAiChatViewModel', () {
    test('adds user and assistant messages on success', () async {
      final viewModel = PublicationAiChatViewModel(
        aiService: _FakeOpenRouterService(answer: 'A careful summary.'),
        publication: _publication(),
      );

      await viewModel.sendMessage('Summarize this paper');

      expect(viewModel.messages, hasLength(2));
      expect(viewModel.messages.first.content, 'Summarize this paper');
      expect(viewModel.messages.last.content, 'A careful summary.');
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('keeps user message and exposes error on failure', () async {
      final viewModel = PublicationAiChatViewModel(
        aiService: _FakeOpenRouterService(
          error: const OpenRouterException('Missing API key'),
        ),
        publication: _publication(),
      );

      await viewModel.sendMessage('Find the gap');

      expect(viewModel.messages, hasLength(1));
      expect(viewModel.messages.single.content, 'Find the gap');
      expect(viewModel.errorMessage, 'Missing API key');
      expect(viewModel.isLoading, isFalse);
    });

    test('ignores blank messages', () async {
      final viewModel = PublicationAiChatViewModel(
        aiService: _FakeOpenRouterService(answer: 'Unused'),
        publication: _publication(),
      );

      await viewModel.sendMessage('   ');

      expect(viewModel.messages, isEmpty);
    });
  });
}

Publication _publication() {
  return Publication(
    id: 'W1',
    title: 'AI in Healthcare',
    publicationYear: 2026,
    citedByCount: 12,
    journalName: 'Journal of AI',
    doi: 'https://doi.org/10.1/test',
    abstractText: 'This paper studies AI in healthcare.',
    authors: const ['Ada Lovelace'],
    oaUrl: 'https://example.com/paper.pdf',
    relatedWorkIds: const [],
    referencedWorkIds: const [],
  );
}

class _FakeOpenRouterService extends OpenRouterService {
  _FakeOpenRouterService({this.answer, this.error})
    : super(client: http.Client(), apiKey: 'fake-key');

  final String? answer;
  final OpenRouterException? error;

  @override
  Future<String> askPublication({
    required PublicationAiContext context,
    required List<AiChatMessage> recentMessages,
    required String userMessage,
  }) async {
    if (error != null) throw error!;
    return answer ?? '';
  }
}
