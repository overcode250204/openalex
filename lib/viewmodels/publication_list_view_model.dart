// Dùng chung cho Related / Cited By / References
import 'package:flutter/foundation.dart';
import 'package:openalex/services/openalex_service.dart';
import '../models/publication/journal_group.dart';
import '../models/publication/publication.dart';

enum ListType { related, citedBy, references }

class PublicationListViewModel extends ChangeNotifier {
  final OpenAlexService _service;

  PublicationListViewModel({OpenAlexService? service})
    : _service = service ?? OpenAlexService();

  List<Publication> _items = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  List<Publication> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  List<JournalGroup> get journalGroups => JournalGroup.groupByJournal(_items);

  Future<void> load({
    required ListType type,
    required String workId,
    List<String>? ids, // dùng cho related & references
    bool reset = true,
  }) async {
    if (reset) {
      _items = [];
      _page = 1;
      _hasMore = true;
    }
    _isLoading = true;
    notifyListeners();

    List<Publication> results = [];

    switch (type) {
      case ListType.related:
      case ListType.references:
        if (ids != null && ids.isNotEmpty) {
          // Phân trang thủ công vì fetchByIds nhận list IDs
          final start = (_page - 1) * 20;
          final batch = ids.skip(start).toList();
          results = await _service.fetchByIds(batch);
          _hasMore = batch.length > 20;
        }
        break;
      case ListType.citedBy:
        results = await _service.fetchCitedBy(workId, page: _page);
        _hasMore = results.length == 20;
        break;
    }

    _items = reset ? results : [..._items, ...results];
    _page++;
    _isLoading = false;
    notifyListeners();
  }
}
