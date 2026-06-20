class KeywordAnalysisPaper {
  final String id;
  final String title;
  final int? publicationYear;
  final String? publicationDate;
  final String? sourceName;
  final String? doi;
  final String? landingPageUrl;
  final String? pdfUrl;
  final int citedByCount;
  final bool isOpenAccess;
  final double keywordScore;

  const KeywordAnalysisPaper({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.publicationDate,
    required this.sourceName,
    required this.doi,
    required this.citedByCount,
    required this.isOpenAccess,
    this.landingPageUrl,
    this.pdfUrl,
    this.keywordScore = 0.0,
  });

  factory KeywordAnalysisPaper.fromJson(Map<String, dynamic> json) {
    return KeywordAnalysisPaper.fromOpenAlexJson(json);
  }

  factory KeywordAnalysisPaper.fromOpenAlexJson(
    Map<String, dynamic> json, {
    String? matchedKeywordId,
  }) {
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    final primarySource = primaryLocation?['source'] as Map<String, dynamic>?;
    final bestOaLocation = json['best_oa_location'] as Map<String, dynamic>?;
    final openAccess = json['open_access'] as Map<String, dynamic>?;

    return KeywordAnalysisPaper(
      id: json['id']?.toString() ?? '',
      title: _parseTitle(json['display_name']),
      publicationYear: json['publication_year'] is int
          ? json['publication_year'] as int
          : null,
      publicationDate: json['publication_date']?.toString(),
      sourceName: primarySource?['display_name']?.toString(),
      doi: json['doi']?.toString(),
      citedByCount: json['cited_by_count'] is int
          ? json['cited_by_count'] as int
          : 0,
      isOpenAccess:
          openAccess?['is_oa'] as bool? ?? json['is_oa'] as bool? ?? false,
      landingPageUrl:
          primaryLocation?['landing_page_url']?.toString() ??
          bestOaLocation?['landing_page_url']?.toString(),
      pdfUrl:
          bestOaLocation?['pdf_url']?.toString() ??
          primaryLocation?['pdf_url']?.toString(),
      keywordScore: _extractKeywordScore(json['keywords'], matchedKeywordId),
    );
  }

  String get displaySource => sourceName ?? 'Unknown source';

  String get displayYearAndSource {
    final year = publicationYear?.toString() ?? 'Unknown year';
    return '$year • $displaySource';
  }

  bool get isFutureDated {
    final now = DateTime.now().toUtc();

    if (publicationYear != null && publicationYear! > now.year) {
      return true;
    }

    if (publicationDate != null && publicationDate!.isNotEmpty) {
      final parsed = DateTime.tryParse(publicationDate!);
      if (parsed != null && parsed.toUtc().isAfter(now)) {
        return true;
      }
    }

    return false;
  }

  static double _extractKeywordScore(
    dynamic keywordsJson,
    String? matchedKeywordId,
  ) {
    if (matchedKeywordId == null || matchedKeywordId.trim().isEmpty) {
      return 0.0;
    }

    if (keywordsJson is! List) {
      return 0.0;
    }

    final normalizedMatchedId = matchedKeywordId.trim().toLowerCase();

    for (final item in keywordsJson) {
      if (item is! Map<String, dynamic>) continue;

      final id = item['id']?.toString().trim().toLowerCase();
      if (id != normalizedMatchedId) continue;

      final score = item['score'];
      if (score is num) {
        return score.toDouble();
      }
    }

    return 0.0;
  }

  static String _parseTitle(Object? value) {
    final title = value?.toString().trim() ?? '';
    return title.isEmpty ? 'Untitled paper' : title;
  }
}
