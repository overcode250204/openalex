class KeywordFrequencyStat {
  final int totalKeywordsAnalyzed;
  final int totalRecentPublications;
  final String hottestKeyword;
  final double fastestGrowthRate;

  const KeywordFrequencyStat({
    required this.totalKeywordsAnalyzed,
    required this.totalRecentPublications,
    required this.hottestKeyword,
    required this.fastestGrowthRate,
  });
}
