import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:openalex/models/ai/ai_chat_message.dart';
import 'package:openalex/models/ai/publication_ai_context.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/services/ai/openrouter_service.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:openalex/viewmodels/publication_ai_chat_view_model.dart';
import 'package:openalex/widgets/ai/publication_ai_chat_panel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('PublicationAiChatPanel sends a question and renders answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (_) => PublicationAiChatViewModel(
              aiService: _FakeOpenRouterService(
                answer: 'This paper studies AI-assisted care.',
              ),
              publication: _publication(),
            ),
            child: const PublicationAiChatPanel(),
          ),
        ),
      ),
    );

    expect(find.byKey(AppKeys.publicationAiChatPanel), findsOneWidget);
    expect(find.text('Ask AI about this paper'), findsOneWidget);

    await tester.enterText(
      find.byKey(AppKeys.publicationAiChatInput),
      'Summarize this paper',
    );
    await tester.tap(find.byKey(AppKeys.publicationAiChatSendButton));
    await tester.pumpAndSettle();

    expect(find.text('Summarize this paper'), findsOneWidget);
    expect(find.text('This paper studies AI-assisted care.'), findsOneWidget);
  });

  testWidgets('PublicationAiChatPanel prompt chip sends suggested prompt', (
    tester,
  ) async {
    final fakeService = _FakeOpenRouterService(
      answer: 'Possible gap: validation.',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (_) => PublicationAiChatViewModel(
              aiService: fakeService,
              publication: _publication(),
            ),
            child: const PublicationAiChatPanel(),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(AppKeys.publicationAiPromptChip('research_gap')),
    );
    await tester.pumpAndSettle();

    expect(fakeService.lastUserMessage, contains('research gaps'));
    expect(find.text('Possible gap: validation.'), findsOneWidget);
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
  _FakeOpenRouterService({required this.answer})
    : super(client: http.Client(), apiKey: 'fake-key');

  final String answer;
  String? lastUserMessage;

  @override
  Future<String> askPublication({
    required PublicationAiContext context,
    required List<AiChatMessage> recentMessages,
    required String userMessage,
  }) async {
    lastUserMessage = userMessage;
    return answer;
  }
}
