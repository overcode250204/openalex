import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/widgets/ai/ai_research_assistant_button.dart';

Widget _buildButton({
  Size size = const Size(390, 844),
  VoidCallback? onPressed,
  bool showLabelOnWide = true,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Center(
          child: AiResearchAssistantButton(
            onPressed: onPressed,
            showLabelOnWide: showLabelOnWide,
            label: 'Ask AI',
            subtitle: 'Your research assistant',
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AiResearchAssistantButton', () {
    testWidgets('renders compact circular button on narrow screens', (
      tester,
    ) async {
      await tester.pumpWidget(_buildButton());

      expect(find.byType(AiResearchAssistantButton), findsOneWidget);
      expect(find.text('Ask AI'), findsNothing);
      expect(find.text('Your research assistant'), findsNothing);
    });

    testWidgets('renders label and subtitle on wide screens', (tester) async {
      await tester.pumpWidget(_buildButton(size: const Size(900, 700)));

      expect(find.text('Ask AI'), findsOneWidget);
      expect(find.text('Your research assistant'), findsOneWidget);
    });

    testWidgets('respects explicit label visibility flag on wide screens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildButton(size: const Size(900, 700), showLabelOnWide: false),
      );

      expect(find.text('Ask AI'), findsNothing);
      expect(find.text('Your research assistant'), findsNothing);
    });

    testWidgets('calls injected action instead of opening default panel', (
      tester,
    ) async {
      var taps = 0;

      await tester.pumpWidget(_buildButton(onPressed: () => taps++));
      await tester.tap(find.byType(AiResearchAssistantButton));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.text('OpenAlex Research Assistant'), findsNothing);
    });

    testWidgets('opens research assistant panel when no action is injected', (
      tester,
    ) async {
      await tester.pumpWidget(_buildButton());

      await tester.tap(find.byType(AiResearchAssistantButton));
      await tester.pumpAndSettle();

      expect(find.text('OpenAlex Research Assistant'), findsOneWidget);
      expect(find.text('Analyze this keyword'), findsOneWidget);
    });
  });
}
