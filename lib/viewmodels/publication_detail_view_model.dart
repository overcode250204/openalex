import 'package:flutter/foundation.dart';
import 'package:openalex/services/openalex_service.dart';

import '../models/publication/publication.dart';
import '../services/zotero_service.dart';

enum DetailState { idle, loading, success, error }

class PublicationDetailViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  ZoteroService? _zoteroService;

  PublicationDetailViewModel({
    OpenAlexService? service,
    ZoteroService? zoteroService,
  }) : _service = service ?? OpenAlexService(),
       _zoteroService = zoteroService;

  Publication? _publication;
  DetailState _state = DetailState.idle;
  String? _error;

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
  }

  Future<String> saveToZotero(Publication publication) {
    return (_zoteroService ??= ZoteroService()).savePublicationToZotero(
      publication,
    );
  }
}
