import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/keyword/openalex_keyword.dart';
import '../../services/openalex_keyword_service.dart';
import '../../viewmodels/keyword_analyzer_view_model.dart';
import '../keyword_analyzer_page.dart';

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
    return ChangeNotifierProvider(
      create: (_) => KeywordAnalyzerViewModel(OpenAlexKeywordService()),
      child: KeywordAnalyzerPage(
        selectedKeyword: selectedKeyword,
        originalSearchText: originalSearchText,
        showBackToDashboard: true,
      ),
    );
  }
}
