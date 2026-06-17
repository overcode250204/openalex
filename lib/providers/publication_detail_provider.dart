import 'package:flutter/foundation.dart';
import 'package:openalex/services/openalex_service.dart';
import '../models/publication.dart';

enum DetailState { idle, loading, success, error }

class PublicationDetailProvider extends ChangeNotifier {
  final _service = OpenAlexService();

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
}