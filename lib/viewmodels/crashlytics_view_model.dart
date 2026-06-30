import 'package:flutter/foundation.dart';

import '../services/firebase/crashlytics_service.dart';

class CrashlyticsViewModel extends ChangeNotifier {
  CrashlyticsViewModel(this._service);

  final AppCrashlyticsService _service;

  bool _isRecordingHandledException = false;
  bool _isTriggeringCrash = false;
  String? _errorMessage;

  bool get isRecordingHandledException => _isRecordingHandledException;
  bool get isTriggeringCrash => _isTriggeringCrash;
  String? get errorMessage => _errorMessage;

  Future<bool> recordDemoHandledException() async {
    if (_isRecordingHandledException) return false;

    _isRecordingHandledException = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.recordDemoHandledException();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to send handled exception to Crashlytics.';
      return false;
    } finally {
      _isRecordingHandledException = false;
      notifyListeners();
    }
  }

  Future<bool> triggerDemoCrash() async {
    if (_isTriggeringCrash) return false;

    _isTriggeringCrash = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.triggerDemoCrash();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to send test crash to Crashlytics.';
      return false;
    } finally {
      _isTriggeringCrash = false;
      notifyListeners();
    }
  }
}
