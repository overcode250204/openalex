import 'package:flutter/foundation.dart';

import '../../services/admin/admin_service.dart';

class AdminNotificationsViewModel extends ChangeNotifier {
  AdminNotificationsViewModel(this._service);

  final AdminService _service;

  bool _isSending = false;
  String? _errorMessage;
  bool _sendSucceeded = false;

  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get sendSucceeded => _sendSucceeded;

  Future<void> send({required String title, required String body}) async {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      _errorMessage = 'Title and body are required.';
      notifyListeners();
      return;
    }

    _isSending = true;
    _errorMessage = null;
    _sendSucceeded = false;
    notifyListeners();

    try {
      await _service.sendBroadcastNotification(
        title: title.trim(),
        body: body.trim(),
      );
      _sendSucceeded = true;
    } catch (_) {
      _errorMessage = 'Could not send notification.';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clearStatus() {
    _errorMessage = null;
    _sendSucceeded = false;
    notifyListeners();
  }
}
