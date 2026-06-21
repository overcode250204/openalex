import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'search_history';
  static const _maxHistory = 10;

  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];

    history.remove(keyword);
    history.insert(0, keyword);

    // Giới hạn số lượng
    if (history.length > _maxHistory) {
      history.removeLast();
    }

    await prefs.setStringList(_key, history);
  }

  Future<void> removeHistory(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    history.remove(keyword);
    await prefs.setStringList(_key, history);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
