import 'package:flutter/material.dart';

import '../models/publication.dart';
import '../services/openalex_service.dart';

class PublicationProvider extends ChangeNotifier {
  final OpenAlexService _openAlexService;

  PublicationProvider(this._openAlexService);

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentTopic = '';

  List<Publication> get publications => _publications;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get currentTopic => _currentTopic;

  Future<void> searchPublications({
    required String keyword,
    int? fromYear,
    int? toYear,
  }) async {
    if (keyword.trim().isEmpty) {
      _errorMessage = 'Please enter a research topic.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentTopic = keyword.trim();
    notifyListeners();

    try {
      _publications = await _openAlexService.searchPublications(
        keyword: keyword,
        fromYear: fromYear,
        toYear: toYear,
      );
    } catch (error) {
      _publications = [];
      _errorMessage = 'Cannot load publications. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<int, int> get publicationCountByYear {
    final Map<int, int> result = {};

    for (final publication in _publications) {
      final year = publication.publicationYear;

      if (year != null) {
        result[year] = (result[year] ?? 0) + 1;
      }
    }

    final sortedEntries = result.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  List<Publication> get topInfluentialPapers {
    final sorted = [..._publications]
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));

    return sorted.take(10).toList();
  }

  Map<String, int> get topJournals {
    final Map<String, int> result = {};

    for (final publication in _publications) {
      final journal = publication.journalName ?? 'Unknown journal';
      result[journal] = (result[journal] ?? 0) + 1;
    }

    final sortedEntries = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(10));
  }

  Map<String, int> get topAuthors {
    final Map<String, int> result = {};

    for (final publication in _publications) {
      for (final author in publication.authors) {
        result[author] = (result[author] ?? 0) + 1;
      }
    }

    final sortedEntries = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(10));
  }

  int get totalPublications {
    return _publications.length;
  }

  double get averageCitationCount {
    if (_publications.isEmpty) {
      return 0;
    }

    final totalCitations = _publications.fold<int>(
      0,
      (sum, publication) => sum + publication.citedByCount,
    );

    return totalCitations / _publications.length;
  }

  int? get mostActiveYear {
    final data = publicationCountByYear;

    if (data.isEmpty) {
      return null;
    }

    return data.entries.reduce((a, b) {
      return a.value >= b.value ? a : b;
    }).key;
  }

  String? get topJournal {
    final data = topJournals;

    if (data.isEmpty) {
      return null;
    }

    return data.entries.first.key;
  }

  String? get topAuthor {
    final data = topAuthors;

    if (data.isEmpty) {
      return null;
    }

    return data.entries.first.key;
  }

  Publication? get mostInfluentialPaper {
    if (_publications.isEmpty) {
      return null;
    }

    return topInfluentialPapers.first;
  }
}
