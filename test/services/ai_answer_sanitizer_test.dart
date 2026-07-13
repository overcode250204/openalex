import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/services/ai/ai_answer_sanitizer.dart';

void main() {
  group('AiAnswerSanitizer', () {
    const sanitizer = AiAnswerSanitizer();

    test('returns a trimmed final answer', () {
      final result = sanitizer.sanitize('Reasoning...\nFinal answer: Hello AI');

      expect(result, 'Hello AI');
    });

    test('strips common markdown formatting', () {
      final result = sanitizer.sanitize('''
Final answer:
## Summary
- **Contribution**: improves retrieval.
- See [OpenAlex](https://openalex.org).
''');

      expect(
        result,
        'Summary\nContribution: improves retrieval.\nSee OpenAlex.',
      );
    });

    test('strips provider metadata before markdown formatting', () {
      final result = sanitizer.sanitize('''
model: openrouter/free
provider: openrouter
usage: prompt_tokens=100 completion_tokens=20
assistant:
Final answer:
### Research Gap
- **Gap**: the abstract does not describe long-term evaluation.
''');

      expect(
        result,
        'Research Gap\nGap: the abstract does not describe long-term evaluation.',
      );
    });

    test('falls back when answer contains prompt leakage', () {
      final result = sanitizer.sanitize(
        'Final answer: The system prompt says you are an academic research assistant.',
      );

      expect(result, AiAnswerSanitizer.defaultFallback);
    });

    test('falls back when answer is empty', () {
      expect(sanitizer.sanitize('   '), AiAnswerSanitizer.defaultFallback);
    });
  });
}
