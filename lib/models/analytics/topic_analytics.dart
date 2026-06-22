class InfluentialPaperSummary {
  final String id;
  final String title;
  final int citedByCount;
  final int? publicationYear;
  final String? doi;

  const InfluentialPaperSummary({
    required this.id,
    required this.title,
    required this.citedByCount,
    this.publicationYear,
    this.doi,
  });
}

class TopicAnalytics {
  final Map<int, int> publicationTrend;
  final Map<String, int> topKeywords;
  final Map<String, int> institutionRanking;
  final Map<String, int> countryOutput;
  final Map<String, int> topJournals;
  final Map<String, int> topAuthors;
  final int totalWorks;
  final int analyzedWorks;
  final int totalCitations;
  final InfluentialPaperSummary? mostInfluentialPaper;

  const TopicAnalytics({
    required this.publicationTrend,
    required this.topKeywords,
    required this.institutionRanking,
    required this.countryOutput,
    this.topJournals = const {},
    this.topAuthors = const {},
    this.totalWorks = 0,
    this.analyzedWorks = 0,
    this.totalCitations = 0,
    this.mostInfluentialPaper,
  });

  double? get averageCitations =>
      analyzedWorks == 0 ? null : totalCitations / analyzedWorks;

  static TopicAnalytics empty() => const TopicAnalytics(
    publicationTrend: {},
    topKeywords: {},
    institutionRanking: {},
    countryOutput: {},
  );
}
