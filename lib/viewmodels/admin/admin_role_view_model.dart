import 'package:flutter/foundation.dart';

import '../../services/admin/admin_role_service.dart';

/// Client-side role check used only for UI routing (admin shell vs normal
/// app shell). This is NOT a security boundary — every privileged action
/// goes through a Cloud Function that independently re-verifies the caller
/// is an admin server-side via the Admin SDK.
class AdminRoleViewModel extends ChangeNotifier {
  AdminRoleViewModel(this._service);

  final AdminRoleService _service;

  bool _isLoading = false;
  bool _isAdmin = false;
  String? _resolvedForUid;

  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;

  Future<void> refreshForUser(String? uid) async {
    if (uid == null) {
      _isAdmin = false;
      _resolvedForUid = null;
      notifyListeners();
      return;
    }

    if (_resolvedForUid == uid && !_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _isAdmin = await _service.isAdmin(uid);
      _resolvedForUid = uid;
    } catch (_) {
      _isAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
