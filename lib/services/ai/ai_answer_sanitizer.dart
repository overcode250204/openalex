class AiAnswerSanitizer {
  static const defaultFallback =
      'I cannot provide a reliable answer from the available publication details.';

  static final _leakagePatterns = <RegExp>[
    RegExp(r'\bsystem prompt\b', caseSensitive: false),
    RegExp(r'\bdeveloper message\b', caseSensitive: false),
    RegExp(r'\binternal instruction', caseSensitive: false),
    RegExp(r'\bhidden instruction', caseSensitive: false),
    RegExp(r'\bignore previous instructions\b', caseSensitive: false),
    RegExp(r'\byou are an academic research assistant\b', caseSensitive: false),
    RegExp(r'\bPublication metadata and abstract:', caseSensitive: false),
    RegExp(r'<\|.*?\|>'),
  ];

  const AiAnswerSanitizer();

  String sanitize(String rawAnswer) {
    final withoutProviderMetadata = _stripProviderMetadata(rawAnswer);
    final finalAnswer = _extractFinalAnswer(withoutProviderMetadata);
    final withoutMarkdown = _stripMarkdown(finalAnswer);
    final normalized = _normalizeWhitespace(withoutMarkdown);

    if (normalized.isEmpty || _containsLeakage(normalized)) {
      return defaultFallback;
    }

    return normalized;
  }

  String _extractFinalAnswer(String value) {
    final markers = [
      RegExp(r'final answer\s*:\s*', caseSensitive: false),
      RegExp(r'answer\s*:\s*', caseSensitive: false),
    ];

    for (final marker in markers) {
      final matches = marker.allMatches(value).toList();
      if (matches.isNotEmpty) {
        return value.substring(matches.last.end);
      }
    }

    return value;
  }

  String _stripProviderMetadata(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll(
          RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<reasoning>[\s\S]*?</reasoning>', caseSensitive: false),
          '',
        )
        .split('\n')
        .where((line) => !_isProviderMetadataLine(line))
        .join('\n');
  }

  bool _isProviderMetadataLine(String line) {
    final normalized = line.trim();
    if (normalized.isEmpty) return false;

    final metadataPatterns = <RegExp>[
      RegExp(
        r'^(assistant|model|provider|route|usage|tokens?)\s*:',
        caseSensitive: false,
      ),
      RegExp(r'^(prompt|completion|total)_tokens\s*:', caseSensitive: false),
      RegExp(
        r'^(finish_reason|finish reason|id|object|created)\s*:',
        caseSensitive: false,
      ),
      RegExp(
        r'^\{?\s*"(id|object|created|model|provider|usage)"\s*:',
        caseSensitive: false,
      ),
    ];

    return metadataPatterns.any((pattern) => pattern.hasMatch(normalized));
  }

  String _stripMarkdown(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAllMapped(RegExp(r'```[\s\S]*?```'), (match) {
          final block = match.group(0) ?? '';
          return block
              .replaceAll(RegExp(r'^```[a-zA-Z0-9_-]*\n?'), '')
              .replaceAll(RegExp(r'\n?```$'), '');
        })
        .replaceAllMapped(
          RegExp(r'!\[([^\]]*)\]\([^)]+\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]+\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        .replaceAll(RegExp(r'[*_~`]+'), '')
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  String _normalizeWhitespace(String value) {
    return value
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  bool _containsLeakage(String value) {
    return _leakagePatterns.any((pattern) => pattern.hasMatch(value));
  }
}
