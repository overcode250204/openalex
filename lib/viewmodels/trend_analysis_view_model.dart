import 'package:flutter/foundation.dart';

import '../services/openalex_service.dart';

class TrendAnalysisViewModel extends ChangeNotifier {
  final OpenAlexService _service;

  TrendAnalysisViewModel({OpenAlexService? service})
    : _service = service ?? OpenAlexService();

  String _topic = '';
  String _topicId = '';
  bool _isInitialized = false;

  int? selectedTopPapers = 5;

  int? selectedTopJournals = 10;
  bool isLoadingJournals = false;
  bool hasErrorJournals = false;
  Map<String, int>? fetchedJournalsData;

  int? selectedTopAuthors = 10;
  bool isLoadingAuthors = false;
  bool hasErrorAuthors = false;
  Map<String, int>? fetchedAuthorsData;

  Map<int, int>? fetchedTrendData;
  bool isLoadingTrend = false;
  bool hasErrorTrend = false;
  int selectedFromYear = 2014;
  int selectedToYear = DateTime.now().year;

  Future<void> initialize({
    required String topic,
    required String topicId,
  }) async {
    if (topic.trim().isEmpty ||
        topicId.trim().isEmpty ||
        (_isInitialized && _topicId == topicId)) {
      return;
    }

    _topic = topic;
    _topicId = topicId;
    _isInitialized = true;
    fetchedTrendData = null;
    fetchedJournalsData = null;
    fetchedAuthorsData = null;
    notifyListeners();

    await Future.wait([
      loadPublicationTrend(),
      loadTopResearchJournals(limit: selectedTopJournals),
      loadTopContributingAuthors(limit: selectedTopAuthors),
    ]);
  }

  Future<void> updateYearRange({int? fromYear, int? toYear}) async {
    if (fromYear != null) {
      selectedFromYear = fromYear;
      if (selectedFromYear > selectedToYear) {
        selectedToYear = selectedFromYear;
      }
    }
    if (toYear != null) {
      selectedToYear = toYear;
      if (selectedToYear < selectedFromYear) {
        selectedFromYear = selectedToYear;
      }
    }
    notifyListeners();
    await Future.wait([
      loadPublicationTrend(),
      loadTopResearchJournals(limit: selectedTopJournals),
      loadTopContributingAuthors(limit: selectedTopAuthors),
    ]);
  }

  void updateTopPapers(int? limit) {
    selectedTopPapers = limit;
    notifyListeners();
  }

  Future<void> updateTopJournals(int? limit) async {
    selectedTopJournals = limit;
    notifyListeners();
    await loadTopResearchJournals(limit: limit);
  }

  Future<void> updateTopAuthors(int? limit) async {
    selectedTopAuthors = limit;
    notifyListeners();
    await loadTopContributingAuthors(limit: limit);
  }

  Future<void> loadPublicationTrend() async {
    if (_topic.trim().isEmpty) return;
    isLoadingTrend = true;
    hasErrorTrend = false;
    notifyListeners();

    try {
      fetchedTrendData = await _service.fetchPublicationTrend(
        keyword: _topic,
        topicId: _topicId,
        fromYear: selectedFromYear,
        toYear: selectedToYear,
      );
    } catch (_) {
      hasErrorTrend = true;
    } finally {
      isLoadingTrend = false;
      notifyListeners();
    }
  }

  Future<void> loadTopResearchJournals({int? limit}) async {
    if (_topic.trim().isEmpty) return;
    isLoadingJournals = true;
    hasErrorJournals = false;
    notifyListeners();

    try {
      fetchedJournalsData = await _service.fetchTopResearchJournals(
        keyword: _topic,
        limit: limit,
        topicId: _topicId,
        fromYear: selectedFromYear,
        toYear: selectedToYear,
      );
    } catch (_) {
      hasErrorJournals = true;
    } finally {
      isLoadingJournals = false;
      notifyListeners();
    }
  }

  Future<void> loadTopContributingAuthors({int? limit}) async {
    if (_topic.trim().isEmpty) return;
    isLoadingAuthors = true;
    hasErrorAuthors = false;
    notifyListeners();

    try {
      fetchedAuthorsData = await _service.fetchTopContributingAuthors(
        keyword: _topic,
        limit: limit,
        topicId: _topicId,
        fromYear: selectedFromYear,
        toYear: selectedToYear,
      );
    } catch (_) {
      hasErrorAuthors = true;
    } finally {
      isLoadingAuthors = false;
      notifyListeners();
    }
  }
}
