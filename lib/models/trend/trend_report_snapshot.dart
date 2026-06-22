import '../publication/publication.dart';

class TrendReportSnapshot {
  final String topic;
  final List<Publication> publications;
  final Map<int, int> publicationCountByYear;
  final List<Publication> topInfluentialPapers;
  final Map<String, int> topJournals;
  final Map<String, int> topAuthors;
  final int totalPublications;
  final double averageCitationCount;
  final int? mostActiveYear;
  final String? topJournal;
  final String? topAuthor;
  final Publication? mostInfluentialPaper;

  const TrendReportSnapshot({
    required this.topic,
    required this.publications,
    required this.publicationCountByYear,
    required this.topInfluentialPapers,
    required this.topJournals,
    required this.topAuthors,
    required this.totalPublications,
    required this.averageCitationCount,
    required this.mostActiveYear,
    required this.topJournal,
    required this.topAuthor,
    required this.mostInfluentialPaper,
  });
}
