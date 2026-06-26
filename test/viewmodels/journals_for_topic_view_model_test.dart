import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/models/journal/journal_topic_rank.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/viewmodels/journals_for_topic_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';

class _FakeOpenAlexService extends OpenAlexService {
  _FakeOpenAlexService({this.ranks, this.error});

  final List<JournalTopicRank>? ranks;
  final Object? error;
  int callCount = 0;
  String? lastTopicId;
  String? lastKeyword;

  @override
  Future<List<JournalTopicRank>> fetchTopResearchJournalRanks({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async {
    callCount++;
    lastTopicId = topicId;
    lastKeyword = keyword;
    if (error != null) throw error!;
    return ranks ?? const [];
  }
}

class _FakeOpenAlexJournalService extends OpenAlexJournalService {
  _FakeOpenAlexJournalService({this.sources = const []});

  final List<JournalSource> sources;
  List<String>? lastRequestedIds;

  @override
  Future<List<JournalSource>> getSourcesByIds(List<String> sourceIds) async {
    lastRequestedIds = sourceIds;
    return sources.where((s) => sourceIds.contains(s.sourceId)).toList();
  }
}

JournalSource _source({required String sourceId, required String name}) {
  return JournalSource(
    id: 'https://openalex.org/$sourceId',
    sourceId: sourceId,
    displayName: name,
    type: 'journal',
    issnL: null,
    issn: const [],
    worksCount: 1000,
    citedByCount: 50000,
    hIndex: 80,
    hostOrganizationName: null,
  );
}

void main() {
  group('JournalsForTopicViewModel.loadForTopic', () {
    test('status is notSearched when no topic is selected', () async {
      final service = _FakeOpenAlexService();
      final viewModel = JournalsForTopicViewModel(
        service: service,
        journalService: _FakeOpenAlexJournalService(),
      );
      final selectedTopic = SelectedTopicViewModel();

      await viewModel.loadForTopic(selectedTopic);

      expect(viewModel.status, JournalsForTopicStatus.notSearched);
      expect(service.callCount, 0);
    });

    test(
      'loads journals and sets success status for a selected topic',
      () async {
        final service = _FakeOpenAlexService(
          ranks: const [
            JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 10),
            JournalTopicRank(sourceId: 'S2', displayName: 'Journal B', count: 5),
          ],
        );
        final journalService = _FakeOpenAlexJournalService(
          sources: [
            _source(sourceId: 'S1', name: 'Journal A'),
            _source(sourceId: 'S2', name: 'Journal B'),
          ],
        );
        final viewModel = JournalsForTopicViewModel(
          service: service,
          journalService: journalService,
        );
        final selectedTopic = SelectedTopicViewModel()
          ..setTopic(
            'Artificial Intelligence',
            suggestion: TopicSuggestion(
              id: 'T123',
              displayName: 'Artificial Intelligence',
              workCount: 5000,
            ),
          );

        await viewModel.loadForTopic(selectedTopic);

        expect(viewModel.status, JournalsForTopicStatus.success);
        expect(
          viewModel.journals.map((j) => j.displayName).toList(),
          ['Journal A', 'Journal B'],
        );
        expect(service.lastTopicId, 'T123');
      },
    );

    test('preserves rank order even if the source batch returns out of order', () async {
      final service = _FakeOpenAlexService(
        ranks: const [
          JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 10),
          JournalTopicRank(sourceId: 'S2', displayName: 'Journal B', count: 5),
        ],
      );
      final journalService = _FakeOpenAlexJournalService(
        sources: [
          _source(sourceId: 'S2', name: 'Journal B'),
          _source(sourceId: 'S1', name: 'Journal A'),
        ],
      );
      final viewModel = JournalsForTopicViewModel(
        service: service,
        journalService: journalService,
      );
      final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

      await viewModel.loadForTopic(selectedTopic);

      expect(
        viewModel.journals.map((j) => j.sourceId).toList(),
        ['S1', 'S2'],
      );
    });

    test(
      'drops ranked journals whose source metadata could not be resolved',
      () async {
        final service = _FakeOpenAlexService(
          ranks: const [
            JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 10),
            JournalTopicRank(sourceId: 'S2', displayName: 'Journal B', count: 5),
          ],
        );
        // Only S1 resolves; S2 is missing from the journal-metadata batch.
        final journalService = _FakeOpenAlexJournalService(
          sources: [_source(sourceId: 'S1', name: 'Journal A')],
        );
        final viewModel = JournalsForTopicViewModel(
          service: service,
          journalService: journalService,
        );
        final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

        await viewModel.loadForTopic(selectedTopic);

        expect(viewModel.status, JournalsForTopicStatus.success);
        expect(viewModel.journals.map((j) => j.sourceId).toList(), ['S1']);
      },
    );

    test('sets empty status when no journals are found for the topic', () async {
      final service = _FakeOpenAlexService(ranks: const []);
      final viewModel = JournalsForTopicViewModel(
        service: service,
        journalService: _FakeOpenAlexJournalService(),
      );
      final selectedTopic = SelectedTopicViewModel()..setTopic('Niche Topic');

      await viewModel.loadForTopic(selectedTopic);

      expect(viewModel.status, JournalsForTopicStatus.empty);
      expect(viewModel.journals, isEmpty);
    });

    test('sets error status and message when the service throws', () async {
      final service = _FakeOpenAlexService(error: Exception('network down'));
      final viewModel = JournalsForTopicViewModel(
        service: service,
        journalService: _FakeOpenAlexJournalService(),
      );
      final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

      await viewModel.loadForTopic(selectedTopic);

      expect(viewModel.status, JournalsForTopicStatus.error);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.journals, isEmpty);
    });

    test('does not refetch when called again for the same topic', () async {
      final service = _FakeOpenAlexService(
        ranks: const [
          JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 1),
        ],
      );
      final journalService = _FakeOpenAlexJournalService(
        sources: [_source(sourceId: 'S1', name: 'Journal A')],
      );
      final viewModel = JournalsForTopicViewModel(
        service: service,
        journalService: journalService,
      );
      final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

      await viewModel.loadForTopic(selectedTopic);
      await viewModel.loadForTopic(selectedTopic);

      expect(service.callCount, 1);
    });

    test('refetches when the selected topic changes', () async {
      final service = _FakeOpenAlexService(
        ranks: const [
          JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 1),
        ],
      );
      final journalService = _FakeOpenAlexJournalService(
        sources: [_source(sourceId: 'S1', name: 'Journal A')],
      );
      final viewModel = JournalsForTopicViewModel(
        service: service,
        journalService: journalService,
      );
      final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

      await viewModel.loadForTopic(selectedTopic);
      selectedTopic.setTopic('Climate Change');
      await viewModel.loadForTopic(selectedTopic);

      expect(service.callCount, 2);
    });

    test('resets to notSearched when the topic is cleared', () async {
      final service = _FakeOpenAlexService(
        ranks: const [
          JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 1),
        ],
      );
      final journalService = _FakeOpenAlexJournalService(
        sources: [_source(sourceId: 'S1', name: 'Journal A')],
      );
      final viewModel = JournalsForTopicViewModel(
        service: service,
        journalService: journalService,
      );
      final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

      await viewModel.loadForTopic(selectedTopic);
      expect(viewModel.status, JournalsForTopicStatus.success);

      selectedTopic.clearTopic();
      await viewModel.loadForTopic(selectedTopic);

      expect(viewModel.status, JournalsForTopicStatus.notSearched);
      expect(viewModel.journals, isEmpty);
    });
  });

  group('JournalsForTopicViewModel.retry', () {
    test('refetches even when the topic key has not changed', () async {
      final service = _FakeOpenAlexService(
        ranks: const [
          JournalTopicRank(sourceId: 'S1', displayName: 'Journal A', count: 1),
        ],
      );
      final journalService = _FakeOpenAlexJournalService(
        sources: [_source(sourceId: 'S1', name: 'Journal A')],
      );
      final viewModel = JournalsForTopicViewModel(
        service: service,
        journalService: journalService,
      );
      final selectedTopic = SelectedTopicViewModel()..setTopic('AI');

      await viewModel.loadForTopic(selectedTopic);
      await viewModel.retry(selectedTopic);

      expect(service.callCount, 2);
      expect(viewModel.status, JournalsForTopicStatus.success);
    });
  });
}
