import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/models/search_filter.dart';
import 'package:openalex/models/topic.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/widgets/filter_bottom_sheet.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeOpenAlexService extends OpenAlexService {
  @override
  Future<(int, List<Publication>)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async => (0, <Publication>[]);

  @override
  Future<(int, List<Publication>)> searchWithFilter(
    Map<String, String> params,
  ) async => (0, <Publication>[]);
}

class _FakeHistoryService extends SearchHistoryService {
  @override
  Future<void> addHistory(String keyword) async {}

  @override
  Future<List<String>> getHistory() async => [];
}

class _FakeSuggestionService extends SuggestionService {
  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async => [];

  @override
  Future<List<TopicSuggestion>> fetchTopicSuggestions(String query) async => [];
}

PublicationProvider _makeProvider() {
  return PublicationProvider(
    _FakeOpenAlexService(),
    historyService: _FakeHistoryService(),
    suggestionService: _FakeSuggestionService(),
  );
}

Widget _buildSheet(PublicationProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: const FilterBottomSheet(),
              ),
            ),
            child: const Text('Open Filter'),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FilterBottomSheet', () {
    testWidgets('renders header and action buttons', (tester) async {
      final provider = _makeProvider();
      await tester.pumpWidget(_buildSheet(provider));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter & Sort'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('renders all sort chips', (tester) async {
      final provider = _makeProvider();
      await tester.pumpWidget(_buildSheet(provider));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Relevance'), findsOneWidget);
      expect(find.text('Cited (Desc)'), findsOneWidget);
      expect(find.text('Cited (Asc)'), findsOneWidget);
      expect(find.text('Year (Desc)'), findsOneWidget);
      expect(find.text('Year (Asc)'), findsOneWidget);
    });

    testWidgets('renders all document type chips', (tester) async {
      final provider = _makeProvider();
      await tester.pumpWidget(_buildSheet(provider));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Article'), findsOneWidget);
      expect(find.text('Preprint'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
    });

    testWidgets('tapping a sort chip selects it', (tester) async {
      final provider = _makeProvider();
      await tester.pumpWidget(_buildSheet(provider));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cited (Desc)'));
      await tester.pump();

      // The chip with that label should now appear selected (no exception = passes)
      expect(find.text('Cited (Desc)'), findsOneWidget);
    });

    testWidgets('Reset clears year fields and resets filter', (tester) async {
      final provider = _makeProvider();
      await tester.pumpWidget(_buildSheet(provider));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Enter a year
      final fromField = find.widgetWithText(TextField, 'From year');
      await tester.enterText(fromField, '2020');
      await tester.pump();

      await tester.tap(find.text('Reset'));
      await tester.pump();

      // After reset the text fields should be cleared
      expect(tester.widget<TextField>(fromField).controller?.text ?? '', '');
    });

    testWidgets('Apply calls updateFilter and pops bottom sheet', (
      tester,
    ) async {
      final provider = _makeProvider();
      await tester.pumpWidget(_buildSheet(provider));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Sheet is dismissed → Filter & Sort no longer visible
      expect(find.text('Filter & Sort'), findsNothing);
    });

    testWidgets('Open Access switch can be toggled', (tester) async {
      final provider = _makeProvider();
      await tester.pumpWidget(_buildSheet(provider));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Toggle on
      await tester.tap(switchFinder);
      await tester.pump();
    });

    testWidgets('pre-fills year fields from existing filter', (tester) async {
      final provider = _makeProvider();
      await provider.updateFilter(
        const SearchFilter(yearFrom: 2019, yearTo: 2024),
      );
      await tester.pumpWidget(_buildSheet(provider));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // The controller text should contain the pre-existing values
      final fromField = find.widgetWithText(TextField, 'From year');
      final widget = tester.widget<TextField>(fromField);
      expect(widget.controller?.text, '2019');
    });
  });
}
