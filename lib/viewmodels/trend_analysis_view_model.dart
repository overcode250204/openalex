import 'package:flutter/foundation.dart';

import '../models/publication/publication.dart';
import '../services/openalex_service.dart';

class TrendAnalysisViewModel extends ChangeNotifier {
  final OpenAlexService _service;

  TrendAnalysisViewModel({OpenAlexService? service})
    : _service = service ?? OpenAlexService();

  String _topic = '';
  bool _isInitialized = false;

  int? selectedTopPapers = 5;
  bool isLoadingPapers = false;
  bool hasErrorPapers = false;
  List<Publication>? fetchedPapers;

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
    required Map<int, int> initialTrend,
    required List<Publication> initialPapers,
    required Map<String, int> initialJournals,
    required Map<String, int> initialAuthors,
  }) async {
    if (topic.trim().isEmpty || (_isInitialized && _topic == topic)) {
      return;
    }

    _topic = topic;
    _isInitialized = true;
    fetchedTrendData = initialTrend;
    fetchedPapers = initialPapers
        .take(selectedTopPapers ?? initialPapers.length)
        .toList();
    fetchedJournalsData = Map.fromEntries(
      initialJournals.entries.take(
        selectedTopJournals ?? initialJournals.length,
      ),
    );
    fetchedAuthorsData = Map.fromEntries(
      initialAuthors.entries.take(selectedTopAuthors ?? initialAuthors.length),
    );
    notifyListeners();

    await loadPublicationTrend();
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
    await loadPublicationTrend();
  }

  Future<void> updateTopPapers(int? limit) async {
    selectedTopPapers = limit;
    notifyListeners();
    await loadInfluentialPapers(limit: limit);
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

  Future<void> loadInfluentialPapers({int? limit}) async {
    if (_topic.trim().isEmpty) return;
    isLoadingPapers = true;
    hasErrorPapers = false;
    notifyListeners();

    try {
      fetchedPapers = await _service.fetchInfluentialPapers(
        keyword: _topic,
        limit: limit,
      );
    } catch (_) {
      hasErrorPapers = true;
    } finally {
      isLoadingPapers = false;
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
      );
    } catch (_) {
      hasErrorAuthors = true;
    } finally {
      isLoadingAuthors = false;
      notifyListeners();
    }
  }
}
