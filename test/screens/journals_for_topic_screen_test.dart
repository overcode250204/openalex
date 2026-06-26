import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/models/journal/journal_topic_rank.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/screens/journal/journals_for_topic_screen.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/viewmodels/journal_view_model.dart';
import 'package:openalex/viewmodels/journals_for_topic_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';
import 'package:provider/provider.dart';

class _FakeOpenAlexService extends OpenAlexService {
  _FakeOpenAlexService({this.ranks, this.error});

  final List<JournalTopicRank>? ranks;
  final Object? error;

  @override
  Future<List<JournalTopicRank>> fetchTopResearchJournalRanks({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async {
    if (error != null) throw error!;
    return ranks ?? const [];
  }
}

class _FakeOpenAlexJournalService extends OpenAlexJournalService {
  _FakeOpenAlexJournalService({this.sources = const []});

  final List<JournalSource> sources;

  @override
  Future<List<JournalSource>> getSourcesByIds(List<String> sourceIds) async {
    return sources.where((s) => sourceIds.contains(s.sourceId)).toList();
  }
}

JournalSource _source({required String sourceId, required String name}) {
  return JournalSource(
    id: 'https://openalex.org/$sourceId',
    sourceId: sourceId,
    displayName: name,
    type: 'journal',
    issnL: '1234-5678',
    issn: const ['1234-5678'],
    worksCount: 1000,
    citedByCount: 50000,
    hIndex: 80,
    hostOrganizationName: 'Some Publisher',
  );
}

Widget _buildScreen({
  required SelectedTopicViewModel selectedTopic,
  List<JournalTopicRank>? ranks,
  List<JournalSource> sources = const [],
  Object? error,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SelectedTopicViewModel>.value(
        value: selectedTopic,
      ),
      ChangeNotifierProvider<JournalsForTopicViewModel>(
        create: (_) => JournalsForTopicViewModel(
          service: _FakeOpenAlexService(ranks: ranks, error: error),
          journalService: _FakeOpenAlexJournalService(sources: sources),
        ),
      ),
      ChangeNotifierProvider<JournalViewModel>(
        create: (_) => JournalViewModel(
          OpenAlexJournalService(),
          suggestionService: SuggestionService(),
        ),
      ),
    ],
    child: const MaterialApp(home: JournalsForTopicScreen()),
  );
}

void main() {
  group('JournalsForTopicScreen', () {
    testWidgets('shows not-searched message when no topic is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(selectedTopic: SelectedTopicViewModel()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Search a topic on the Home tab to see its top journals here.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows ranked journals reusing the JournalSourceCard UI', (
      tester,
    ) async {
      final selectedTopic = SelectedTopicViewModel()
        ..setTopic(
          'Artificial Intelligence',
          suggestion: TopicSuggestion(
            id: 'T123',
            displayName: 'Artificial Intelligence',
            workCount: 5000,
          ),
        );

      await tester.pumpWidget(
        _buildScreen(
          selectedTopic: selectedTopic,
          ranks: const [
            JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 10),
            JournalTopicRank(sourceId: 'S2', displayName: 'Journal B', count: 5),
          ],
          sources: [
            _source(sourceId: 'S1', name: 'Journal A'),
            _source(sourceId: 'S2', name: 'Journal B'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Results (2)'), findsOneWidget);
      expect(find.text('Top journals for "Artificial Intelligence"'), findsOneWidget);
      expect(find.text('Journal A'), findsOneWidget);
      expect(find.text('Journal B'), findsOneWidget);
      // Reused JournalSourceCard fields.
      expect(find.text('1000'), findsWidgets);
      expect(find.text('Select'), findsWidgets);
    });

    testWidgets('shows empty message when topic has no journals', (
      tester,
    ) async {
      final selectedTopic = SelectedTopicViewModel()..setTopic('Niche Topic');

      await tester.pumpWidget(
        _buildScreen(selectedTopic: selectedTopic, ranks: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('No journals found for this topic.'), findsOneWidget);
    });

    testWidgets('shows error message and retry button on failure', (
      tester,
    ) async {
      final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

      await tester.pumpWidget(
        _buildScreen(
          selectedTopic: selectedTopic,
          error: Exception('network down'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Cannot load journals for this topic. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping the search icon opens Journal Search screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(selectedTopic: SelectedTopicViewModel()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Journal Search'), findsOneWidget);
    });

    testWidgets(
      'tapping Select on a ranked journal opens its detail via JournalViewModel',
      (tester) async {
        final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

        await tester.pumpWidget(
          _buildScreen(
            selectedTopic: selectedTopic,
            ranks: const [
              JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 10),
            ],
            sources: [_source(sourceId: 'S1', name: 'Journal A')],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select').first);
        await tester.pumpAndSettle();

        // Detail view shows the journal's header banner with its name.
        expect(find.text('Journal A'), findsWidgets);
        expect(find.text('Publications'), findsOneWidget);
      },
    );
  });
}
