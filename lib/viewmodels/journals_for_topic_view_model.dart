import 'package:flutter/foundation.dart';

import '../models/journal/journal_source.dart';
import '../services/openalex_journal_service.dart';
import '../services/openalex_service.dart';
import 'selected_topic_view_model.dart';

enum JournalsForTopicStatus { notSearched, loading, error, empty, success }

class JournalsForTopicViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  final OpenAlexJournalService _journalService;

  JournalsForTopicViewModel({
    OpenAlexService? service,
    OpenAlexJournalService? journalService,
  }) : _service = service ?? OpenAlexService(),
       _journalService = journalService ?? OpenAlexJournalService();

  JournalsForTopicStatus _status = JournalsForTopicStatus.notSearched;
  List<JournalSource> _journals = const [];
  String? _errorMessage;
  String? _loadedTopicKey;

  JournalsForTopicStatus get status => _status;
  List<JournalSource> get journals => _journals;
  String? get errorMessage => _errorMessage;

  Future<void> loadForTopic(SelectedTopicViewModel selectedTopic) async {
    if (!selectedTopic.hasSelectedTopic) {
      if (_status != JournalsForTopicStatus.notSearched) {
        _status = JournalsForTopicStatus.notSearched;
        _journals = const [];
        _loadedTopicKey = null;
        notifyListeners();
      }
      return;
    }

    final topicKey =
        selectedTopic.selectedSuggestion?.id ?? selectedTopic.selectedTopic!;

    if (topicKey == _loadedTopicKey) {
      return;
    }
    _loadedTopicKey = topicKey;

    _status = JournalsForTopicStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final ranks = await _service.fetchTopResearchJournalRanks(
        keyword: selectedTopic.selectedTopic ?? '',
        topicId: selectedTopic.selectedSuggestion?.id,
      );

      final sourceIds = ranks
          .map((rank) => rank.sourceId)
          .where((id) => id.isNotEmpty)
          .toList();
      final sources = await _journalService.getSourcesByIds(sourceIds);
      final sourceById = {for (final source in sources) source.sourceId: source};

      _journals = ranks
          .map((rank) => sourceById[rank.sourceId])
          .whereType<JournalSource>()
          .toList();

      _status = _journals.isEmpty
          ? JournalsForTopicStatus.empty
          : JournalsForTopicStatus.success;
    } catch (_) {
      _journals = const [];
      _errorMessage =
          'Cannot load journals for this topic. Please try again.';
      _status = JournalsForTopicStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> retry(SelectedTopicViewModel selectedTopic) async {
    _loadedTopicKey = null;
    await loadForTopic(selectedTopic);
  }
}
