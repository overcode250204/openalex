import 'package:flutter/material.dart';

import '../../models/keyword/keyword_analysis_paper.dart';
import 'keyword_paper_list_card.dart';

class LatestPapersCard extends StatelessWidget {
  final List<KeywordAnalysisPaper> papers;
  final ValueChanged<KeywordAnalysisPaper>? onPaperTap;

  const LatestPapersCard({super.key, required this.papers, this.onPaperTap});

  @override
  Widget build(BuildContext context) {
    return KeywordPaperListCard(
      title: 'Latest Papers',
      emptyMessage: 'No latest papers available.',
      papers: papers,
      onPaperTap: onPaperTap,
      showDate: true,
    );
  }
}
