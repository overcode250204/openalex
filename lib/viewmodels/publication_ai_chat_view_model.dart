import 'package:flutter/foundation.dart';

import '../models/ai/ai_chat_message.dart';
import '../models/ai/publication_ai_context.dart';
import '../models/publication/publication.dart';
import '../services/ai/openrouter_service.dart';

class PublicationAiChatViewModel extends ChangeNotifier {
  final OpenRouterService _aiService;
  final PublicationAiContext _context;

  PublicationAiChatViewModel({
    required OpenRouterService aiService,
    required Publication publication,
  }) : _aiService = aiService,
       _context = PublicationAiContext.fromPublication(publication);

  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMessages => _messages.isNotEmpty;

  Future<void> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty || _isLoading) return;

    final userMessage = AiChatMessage(
      role: AiChatRole.user,
      content: trimmedMessage,
      createdAt: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final answer = await _aiService.askPublication(
        context: _context,
        recentMessages: _messages.length <= 1
            ? const []
            : _messages.take(_messages.length - 1).toList(),
        userMessage: trimmedMessage,
      );

      _messages.add(
        AiChatMessage(
          role: AiChatRole.assistant,
          content: answer,
          createdAt: DateTime.now(),
        ),
      );
    } on OpenRouterException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Cannot get an AI answer right now. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendSuggestedPrompt(String prompt) => sendMessage(prompt);

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    if (_messages.isEmpty) return;
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
