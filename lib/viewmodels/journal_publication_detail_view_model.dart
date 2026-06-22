import 'package:flutter/foundation.dart';

import '../models/journal/journal_publication.dart';
import '../services/openalex_journal_service.dart';

class JournalPublicationDetailViewModel extends ChangeNotifier {
  final OpenAlexJournalService _service;

  JournalPublicationDetailViewModel(this._service);

  JournalPublication? _publication;
  bool _isLoading = false;

  JournalPublication? get publication => _publication;
  bool get isLoading => _isLoading;

  Future<void> load(JournalPublication initialPublication) async {
    _publication = initialPublication;
    if (initialPublication.workId.trim().isEmpty) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final detail = await _service.getPublicationDetail(
        initialPublication.workId,
      );
      if (detail != null) {
        _publication = detail;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
