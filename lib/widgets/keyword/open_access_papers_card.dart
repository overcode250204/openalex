import 'package:flutter/material.dart';

import '../../models/keyword/keyword_analysis_paper.dart';
import 'keyword_paper_list_card.dart';

class OpenAccessPapersCard extends StatelessWidget {
  final List<KeywordAnalysisPaper> papers;
  final ValueChanged<KeywordAnalysisPaper>? onPaperTap;

  const OpenAccessPapersCard({
    super.key,
    required this.papers,
    this.onPaperTap,
  });

  @override
  Widget build(BuildContext context) {
    return KeywordPaperListCard(
      title: 'Open Access Papers',
      emptyMessage: 'No open access papers available.',
      papers: papers,
      onPaperTap: onPaperTap,
      showLinks: true,
    );
  }
}
