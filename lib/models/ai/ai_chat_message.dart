enum AiChatRole { user, assistant }

class AiChatMessage {
  final AiChatRole role;
  final String content;
  final DateTime createdAt;

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == AiChatRole.user;
}
