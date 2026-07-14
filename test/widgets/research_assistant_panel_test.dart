import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/widgets/ai/research_assistant_panel.dart';

Widget _buildPanel() {
  return const MaterialApp(home: Scaffold(body: ResearchAssistantPanel()));
}

void main() {
  group('ResearchAssistantPanel', () {
    testWidgets('renders greeting, header, suggestions, and input', (
      tester,
    ) async {
      await tester.pumpWidget(_buildPanel());

      expect(find.text('OpenAlex Research Assistant'), findsOneWidget);
      expect(find.textContaining('Powered by OpenAlex data'), findsOneWidget);
      expect(
        find.textContaining('I can help you analyze keywords'),
        findsOneWidget,
      );
      expect(find.text('Analyze this keyword'), findsOneWidget);
      expect(find.text('Find related papers'), findsOneWidget);
      expect(find.text('Suggest research gaps'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('quick suggestion sends user message and demo reply', (
      tester,
    ) async {
      await tester.pumpWidget(_buildPanel());

      await tester.tap(find.text('Suggest research gaps'));
      await tester.pump();

      expect(find.text('Suggest research gaps'), findsWidgets);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('potential research gaps include'),
        findsOneWidget,
      );
      expect(find.text('Analyze this keyword'), findsNothing);
      expect(find.text('Find related papers'), findsNothing);
    });

    testWidgets('custom question sends fallback assistant reply', (
      tester,
    ) async {
      await tester.pumpWidget(_buildPanel());

      await tester.enterText(
        find.byType(TextField),
        'How is this topic moving?',
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(find.text('How is this topic moving?'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("That's a great research question"),
        findsOneWidget,
      );
    });

    testWidgets('close button pops the panel route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const ResearchAssistantPanel(),
                  ),
                  child: const Text('Open panel'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open panel'));
      await tester.pumpAndSettle();
      expect(find.text('OpenAlex Research Assistant'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('OpenAlex Research Assistant'), findsNothing);
    });
  });
}
