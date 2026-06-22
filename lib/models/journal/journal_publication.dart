import '../../utils/abstract_converter.dart';

class JournalPublication {
  final String id;
  final String workId;
  final String title;
  final int? publicationYear;
  final String? publicationDate;
  final String? doi;
  final int citedByCount;
  final List<String> authors;
  final String? journalName;
  final String? sourceId;
  final bool isOpenAccess;
  final String? landingPageUrl;
  final String? pdfUrl;
  final String? abstractText;

  const JournalPublication({
    required this.id,
    required this.workId,
    required this.title,
    required this.publicationYear,
    required this.publicationDate,
    required this.doi,
    required this.citedByCount,
    required this.authors,
    required this.journalName,
    required this.sourceId,
    required this.isOpenAccess,
    required this.landingPageUrl,
    required this.pdfUrl,
    required this.abstractText,
  });

  factory JournalPublication.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    final source = primaryLocation?['source'] as Map<String, dynamic>?;
    final openAccess = json['open_access'] as Map<String, dynamic>?;
    final bestOaLocation = json['best_oa_location'] as Map<String, dynamic>?;

    final abstractIndex = json['abstract_inverted_index'];

    return JournalPublication(
      id: id,
      workId: id.split('/').last,
      title:
          json['display_name']?.toString() ??
          json['title']?.toString() ??
          'Untitled',
      publicationYear: json['publication_year'] as int?,
      publicationDate: json['publication_date']?.toString(),
      doi: json['doi']?.toString(),
      citedByCount: json['cited_by_count'] as int? ?? 0,
      authors: (json['authorships'] as List? ?? [])
          .map((item) => item['author']?['display_name']?.toString())
          .whereType<String>()
          .toList(),
      journalName: source?['display_name']?.toString(),
      sourceId: source?['id']?.toString().split('/').last,
      isOpenAccess: openAccess?['is_oa'] as bool? ?? false,
      landingPageUrl: primaryLocation?['landing_page_url']?.toString(),
      pdfUrl:
          primaryLocation?['pdf_url']?.toString() ??
          bestOaLocation?['pdf_url']?.toString() ??
          openAccess?['oa_url']?.toString(),
      abstractText: abstractIndex is Map<String, dynamic>
          ? AbstractConverter.fromInvertedIndex(abstractIndex)
          : null,
    );
  }

  String get displayYear => publicationYear?.toString() ?? 'Unknown year';

  String get displayDate => publicationDate ?? displayYear;

  String get displayDoi =>
      doi?.trim().isNotEmpty == true ? doi! : 'No DOI available';

  String get displayJournal =>
      journalName?.trim().isNotEmpty == true ? journalName! : 'Unknown journal';

  String get displayAuthors {
    if (authors.isEmpty) {
      return 'Unknown authors';
    }

    return authors.join(', ');
  }
}
