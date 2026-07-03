import 'package:flutter/foundation.dart';
import 'package:openalex/services/openalex_service.dart';

import '../models/publication/publication.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/analytics/no_op_analytics_service.dart';
import '../services/zotero_service.dart';

enum DetailState { idle, loading, success, error }

class PublicationDetailViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  final AppAnalyticsService _analyticsService;
  ZoteroService? _zoteroService;

  PublicationDetailViewModel({
    OpenAlexService? service,
    ZoteroService? zoteroService,
    AppAnalyticsService analyticsService = const NoOpAnalyticsService(),
  }) : _service = service ?? OpenAlexService(),
       _analyticsService = analyticsService,
       _zoteroService = zoteroService;

  Publication? _publication;
  DetailState _state = DetailState.idle;
  String? _error;
  final Set<String> _loggedPublicationViews = <String>{};

  Publication? get publication => _publication;
  DetailState get state => _state;
  String? get error => _error;

  Future<void> loadDetail(String workId) async {
    _state = DetailState.loading;
    _publication = null;
    notifyListeners();

    final result = await _service.fetchDetail(workId);
    if (result != null) {
      _publication = result;
      _state = DetailState.success;
    } else {
      _error = 'Can not load paper';
      _state = DetailState.error;
    }
    notifyListeners();

    if (result != null) {
      await _logPublicationView(workId: workId, publication: result);
    }
  }

  Future<void> _logPublicationView({
    required String workId,
    required Publication publication,
  }) async {
    final analyticsKey = publication.id.trim().isNotEmpty
        ? publication.id.trim()
        : workId.trim();
    if (analyticsKey.isEmpty || !_loggedPublicationViews.add(analyticsKey)) {
      return;
    }

    await _analyticsService.logViewPublication(
      publicationTitle: publication.title,
      publicationYear: publication.publicationYear,
    );
  }

  Future<String> saveToZotero(Publication publication) {
    return (_zoteroService ??= ZoteroService()).savePublicationToZotero(
      publication,
    );
  }
}
