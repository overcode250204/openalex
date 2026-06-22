import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_suggestion.dart';
import 'package:openalex/widgets/search/journal_suggestion_dropdown.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('JournalSuggestionDropdown', () {
    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          JournalSuggestionDropdown(
            suggestions: const [],
            isLoading: true,
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Searching journals...'), findsOneWidget);
    });

    testWidgets('shows empty state when no suggestions and not loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          JournalSuggestionDropdown(
            suggestions: const [],
            isLoading: false,
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('No journals found.'), findsNothing);
    });

    testWidgets('shows suggestions list and taps correctly', (tester) async {
      var selectedJournalId = '';
      final suggestions = [
        JournalSuggestion(
          id: 'https://openalex.org/S123',
          displayName: 'Nature',
          worksCount: 1000,
        ),
        JournalSuggestion(
          id: 'https://openalex.org/S456',
          displayName: 'Science',
          worksCount: 800,
          publisher: 'AAAS',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          JournalSuggestionDropdown(
            suggestions: suggestions,
            isLoading: false,
            onSelected: (suggestion) {
              selectedJournalId = suggestion.shortId;
            },
          ),
        ),
      );

      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
      expect(find.textContaining('AAAS'), findsOneWidget);

      await tester.tap(find.text('Nature'));
      await tester.pump();

      expect(selectedJournalId, 'S123');
    });
  });
}
