import 'package:flutter/foundation.dart';

import '../../services/admin/admin_service.dart';

class AdminRemoteConfigViewModel extends ChangeNotifier {
  AdminRemoteConfigViewModel(this._service);

  final AdminService _service;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _saveSucceeded = false;
  int? _maxJournalsDisplayed;
  int? _maxKeywordsDisplayed;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get saveSucceeded => _saveSucceeded;
  int? get maxJournalsDisplayed => _maxJournalsDisplayed;
  int? get maxKeywordsDisplayed => _maxKeywordsDisplayed;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final values = await _service.getRemoteConfigValues();
      _maxJournalsDisplayed = values.maxJournalsDisplayed;
      _maxKeywordsDisplayed = values.maxKeywordsDisplayed;
    } catch (_) {
      _errorMessage = 'Could not load Remote Config values.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({int? maxJournalsDisplayed, int? maxKeywordsDisplayed}) async {
    _isSaving = true;
    _errorMessage = null;
    _saveSucceeded = false;
    notifyListeners();

    try {
      await _service.updateRemoteConfigValues(
        maxJournalsDisplayed: maxJournalsDisplayed,
        maxKeywordsDisplayed: maxKeywordsDisplayed,
      );
      _maxJournalsDisplayed = maxJournalsDisplayed ?? _maxJournalsDisplayed;
      _maxKeywordsDisplayed = maxKeywordsDisplayed ?? _maxKeywordsDisplayed;
      _saveSucceeded = true;
    } catch (_) {
      _errorMessage = 'Could not save Remote Config values.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
