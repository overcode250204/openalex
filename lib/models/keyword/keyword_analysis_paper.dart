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

  const KeywordAnalysisPaper({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.publicationDate,
    required this.sourceName,
    required this.doi,
    required this.landingPageUrl,
    required this.pdfUrl,
    required this.citedByCount,
    required this.isOpenAccess,
  });

  factory KeywordAnalysisPaper.fromJson(Map<String, dynamic> json) {
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    final primarySource = primaryLocation?['source'] as Map<String, dynamic>?;
    final bestOaLocation = json['best_oa_location'] as Map<String, dynamic>?;
    final openAccess = json['open_access'] as Map<String, dynamic>?;

    return KeywordAnalysisPaper(
      id: json['id']?.toString() ?? '',
      title: json['display_name']?.toString() ?? 'No title',
      publicationYear: json['publication_year'] as int?,
      publicationDate: json['publication_date']?.toString(),
      sourceName: primarySource?['display_name']?.toString(),
      doi: json['doi']?.toString(),
      landingPageUrl:
          primaryLocation?['landing_page_url']?.toString() ??
          bestOaLocation?['landing_page_url']?.toString(),
      pdfUrl:
          bestOaLocation?['pdf_url']?.toString() ??
          primaryLocation?['pdf_url']?.toString(),
      citedByCount: json['cited_by_count'] as int? ?? 0,
      isOpenAccess:
          openAccess?['is_oa'] as bool? ?? json['is_oa'] as bool? ?? false,
    );
  }

  String get displaySource => sourceName ?? 'Unknown source';

  String get displayDate {
    if (publicationDate != null && publicationDate!.trim().isNotEmpty) {
      return publicationDate!;
    }
    return publicationYear?.toString() ?? 'Unknown year';
  }

  String get displayYearAndSource {
    final year = publicationYear?.toString() ?? 'Unknown year';
    return '$year - $displaySource';
  }
}
