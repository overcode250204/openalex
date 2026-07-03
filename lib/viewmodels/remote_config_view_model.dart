import 'package:flutter/foundation.dart';
import '../services/firebase/remote_config_service.dart';

class RemoteConfigViewModel extends ChangeNotifier {
  RemoteConfigViewModel(this._service);

  final AppRemoteConfigService _service;

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  int get maxJournalsDisplayed => _service.maxJournalsDisplayed;
  int get maxKeywordsDisplayed => _service.maxKeywordsDisplayed;

  Future<void> initialize() async {
    await _service.initialize();
    notifyListeners();
  }

  Future<void> fetchAndActivate() async {
    if (_isFetching) return;

    _isFetching = true;
    notifyListeners();

    try {
      await _service.fetchAndActivate();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }
}
