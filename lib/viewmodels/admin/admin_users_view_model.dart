import 'package:flutter/foundation.dart';

import '../../models/admin/admin_user_summary.dart';
import '../../services/admin/admin_service.dart';

class AdminUsersViewModel extends ChangeNotifier {
  AdminUsersViewModel(this._service);

  final AdminService _service;

  List<AdminUserSummary> _users = [];
  String? _nextPageToken;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final Set<String> _mutatingUids = {};

  List<AdminUserSummary> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextPageToken != null;
  String? get errorMessage => _errorMessage;

  bool isMutating(String uid) => _mutatingUids.contains(uid);

  Future<void> loadFirstPage() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _service.listUsers();
      _users = page.users;
      _nextPageToken = page.nextPageToken;
    } catch (_) {
      _errorMessage = 'Could not load users.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _nextPageToken == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _service.listUsers(pageToken: _nextPageToken);
      _users = [..._users, ...page.users];
      _nextPageToken = page.nextPageToken;
    } catch (_) {
      _errorMessage = 'Could not load more users.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setDisabled(String uid, bool disabled) async {
    _mutatingUids.add(uid);
    notifyListeners();

    try {
      await _service.setUserDisabled(uid: uid, disabled: disabled);
      _users = _users
          .map((u) => u.uid == uid ? u.copyWith(disabled: disabled) : u)
          .toList();
    } catch (_) {
      _errorMessage = 'Could not update user.';
    } finally {
      _mutatingUids.remove(uid);
      notifyListeners();
    }
  }

  Future<void> setRole(String uid, bool isAdmin) async {
    _mutatingUids.add(uid);
    notifyListeners();

    try {
      await _service.setUserRole(uid: uid, isAdmin: isAdmin);
      _users = _users
          .map((u) => u.uid == uid ? u.copyWith(isAdmin: isAdmin) : u)
          .toList();
    } catch (_) {
      _errorMessage = 'Could not update role.';
    } finally {
      _mutatingUids.remove(uid);
      notifyListeners();
    }
  }
}
