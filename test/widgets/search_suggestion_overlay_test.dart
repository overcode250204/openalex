import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/viewmodels/home_view_model.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/widgets/search_suggestion_overlay.dart';
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
}

class _FakeHistoryService extends SearchHistoryService {
  final List<String> _history;

  _FakeHistoryService(this._history);

  @override
  Future<List<String>> getHistory() async => List.from(_history);

  @override
  Future<void> addHistory(String keyword) async {}

  @override
  Future<void> removeHistory(String keyword) async {
    _history.remove(keyword);
  }

  @override
  Future<void> clearHistory() async {
    _history.clear();
  }
}

class _FakeSuggestionService extends SuggestionService {
  final List<TopicSuggestion> suggestions;

  _FakeSuggestionService({this.suggestions = const []});

  @override
  Future<List<TopicSuggestion>> fetchTopicSuggestions(String query) async =>
      suggestions;

  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async => [];
}

Widget _buildWidget({
  required HomeViewModel provider,
  required TextEditingController controller,
  ValueChanged<TopicSuggestion?>? onSearch,
}) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(controller: controller),
            SearchSuggestionOverlay(controller: controller, onSearch: onSearch),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SearchSuggestionOverlay', () {
    testWidgets('shows nothing when showSuggestions is false', (tester) async {
      final controller = TextEditingController();
      final provider = HomeViewModel(
        _FakeOpenAlexService(),
        historyService: _FakeHistoryService([]),
        suggestionService: _FakeSuggestionService(),
      );

      await tester.pumpWidget(
        _buildWidget(provider: provider, controller: controller),
      );

      // showSuggestions is initially false → SizedBox is rendered
      expect(find.text('Search history'), findsNothing);
      expect(find.text('Suggestion'), findsNothing);
    });

    testWidgets(
      'shows search history when query is empty and field is focused',
      (tester) async {
        final controller = TextEditingController();
        final provider = HomeViewModel(
          _FakeOpenAlexService(),
          historyService: _FakeHistoryService(['AI', 'Blockchain']),
          suggestionService: _FakeSuggestionService(),
        );

        // Load history then show suggestions via onQueryChanged('')
        await provider.loadHistory();
        await provider.onQueryChanged('');

        await tester.pumpWidget(
          _buildWidget(provider: provider, controller: controller),
        );

        await tester.pump();

        expect(find.text('Search history'), findsOneWidget);
        expect(find.text('AI'), findsOneWidget);
        expect(find.text('Blockchain'), findsOneWidget);
      },
    );

    testWidgets('shows Clear all button for history', (tester) async {
      final controller = TextEditingController();
      final provider = HomeViewModel(
        _FakeOpenAlexService(),
        historyService: _FakeHistoryService(['ML']),
        suggestionService: _FakeSuggestionService(),
      );
      await provider.loadHistory();
      await provider.onQueryChanged('');

      await tester.pumpWidget(
        _buildWidget(provider: provider, controller: controller),
      );
      await tester.pump();

      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets(
      'shows Suggestion section when query is not empty and suggestions exist',
      (tester) async {
        final controller = TextEditingController(text: 'AI');
        final suggestions = [
          TopicSuggestion.fromJson({
            'id': 'T1',
            'display_name': 'Artificial Intelligence',
            'works_count': 5000,
          }),
        ];
        final provider = HomeViewModel(
          _FakeOpenAlexService(),
          historyService: _FakeHistoryService([]),
          suggestionService: _FakeSuggestionService(suggestions: suggestions),
        );

        // Trigger suggestion loading by passing a non-empty query
        await provider.onQueryChanged('AI');

        await tester.pumpWidget(
          _buildWidget(provider: provider, controller: controller),
        );
        await tester.pump();

        expect(find.text('Suggestion'), findsOneWidget);
        expect(find.text('Artificial Intelligence'), findsOneWidget);
      },
    );

    testWidgets(
      'does not show overlay when both history and suggestions are empty',
      (tester) async {
        final controller = TextEditingController();
        final provider = HomeViewModel(
          _FakeOpenAlexService(),
          historyService: _FakeHistoryService([]),
          suggestionService: _FakeSuggestionService(),
        );
        await provider.onQueryChanged('');

        await tester.pumpWidget(
          _buildWidget(provider: provider, controller: controller),
        );
        await tester.pump();

        // Both empty → overlay returns SizedBox
        expect(find.text('Search history'), findsNothing);
        expect(find.text('Suggestion'), findsNothing);
      },
    );

    testWidgets('hideSuggestions hides the overlay', (tester) async {
      final controller = TextEditingController();
      final provider = HomeViewModel(
        _FakeOpenAlexService(),
        historyService: _FakeHistoryService(['AI']),
        suggestionService: _FakeSuggestionService(),
      );

      await provider.loadHistory();
      await provider.onQueryChanged('');

      await tester.pumpWidget(
        _buildWidget(provider: provider, controller: controller),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('search_suggestion_overlay_content')),
        findsOneWidget,
      );
      expect(find.text('Search history'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);

      provider.hideSuggestions();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('search_suggestion_overlay_content')),
        findsNothing,
      );
      expect(find.text('Search history'), findsNothing);
      expect(find.text('AI'), findsNothing);

      controller.dispose();
    });
  });
}
