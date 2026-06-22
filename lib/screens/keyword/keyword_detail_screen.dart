import 'package:flutter/material.dart';
import '../../models/keyword/openalex_keyword.dart';
import 'keyword_analyzer_page_screen.dart';

class KeywordDetailScreen extends StatelessWidget {
  final OpenAlexKeyword selectedKeyword;
  final String? originalSearchText;

  const KeywordDetailScreen({
    super.key,
    required this.selectedKeyword,
    this.originalSearchText,
  });

  @override
  Widget build(BuildContext context) {
    return KeywordAnalyzerPage(
      selectedKeyword: selectedKeyword,
      originalSearchText: originalSearchText,
      showBackToDashboard: true,
    );
  }
}
