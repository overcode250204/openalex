import '../models/topic/topic.dart';

import 'package:flutter/foundation.dart';

/// Shared research-topic state for the application shell and all tab flows.
class SelectedTopicViewModel extends ChangeNotifier {
  String? _selectedTopic;
  TopicSuggestion? _selectedSuggestion;

  String? get selectedTopic => _selectedTopic;
  TopicSuggestion? get selectedSuggestion => _selectedSuggestion;
  bool get hasSelectedTopic => _selectedTopic != null;

  void setTopic(String topic, {TopicSuggestion? suggestion}) {
    final normalizedTopic = topic.trim();
    if (normalizedTopic.isEmpty) {
      clearTopic();
      return;
    }

    if (_selectedTopic == normalizedTopic &&
        _selectedSuggestion == suggestion) {
      return;
    }

    _selectedTopic = normalizedTopic;
    _selectedSuggestion = suggestion;
    notifyListeners();
  }

  void clearTopic() {
    if (_selectedTopic == null && _selectedSuggestion == null) {
      return;
    }

    _selectedTopic = null;
    _selectedSuggestion = null;
    notifyListeners();
  }
}
