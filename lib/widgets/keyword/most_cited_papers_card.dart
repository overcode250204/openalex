import 'package:flutter/material.dart';

import '../../models/keyword/keyword_analysis_paper.dart';
import 'keyword_paper_list_card.dart';

class MostCitedPapersCard extends StatelessWidget {
  final List<KeywordAnalysisPaper> papers;
  final ValueChanged<KeywordAnalysisPaper>? onPaperTap;

  const MostCitedPapersCard({super.key, required this.papers, this.onPaperTap});

  @override
  Widget build(BuildContext context) {
    return KeywordPaperListCard(
      title: 'Most Cited Papers Using This Keyword',
      subtitle: 'Papers with this keyword, sorted by citation count.',
      emptyMessage: 'No cited papers available.',
      papers: papers,
      onPaperTap: onPaperTap,
    );
  }
}
