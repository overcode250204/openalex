import 'package:openalex/core/utils/abstract_converter.dart';

class Publication {
  final String id;
  final String title;
  final int? publicationYear;
  final int citedByCount;
  final String? journalName;
  final String? doi;
  final String? abstractText;
  final List<String> authors;

  final String? oaUrl;
  final List<String> relatedWorkIds;
  final List<String> referencedWorkIds;

  Publication({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.citedByCount,
    required this.journalName,
    required this.doi,
    required this.abstractText,
    required this.authors,
    this.oaUrl,
    required this.relatedWorkIds,
    required this.referencedWorkIds,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    final bestOa = json['best_oa_location'] as Map<String, dynamic>?;
    final openAccess = json['open_access'] as Map<String, dynamic>?;
    final oaUrl = bestOa?['pdf_url'] as String?
        ?? primaryLocation?['pdf_url'] as String?
        ?? openAccess?['oa_url'] as String?;
    return Publication(
      id: json['id']?.toString() ?? '',
      title: json['display_name']?.toString() ?? 'No title',
      publicationYear: json['publication_year'],
      citedByCount: json['cited_by_count'] ?? 0,
      journalName: json['primary_location']?['source']?['display_name'],
      doi: json['doi'],
      abstractText: AbstractConverter.fromInvertedIndex(
        json['abstract_inverted_index'],
      ),
      authors: (json['authorships'] as List? ?? [])
          .map((item) => item['author']?['display_name']?.toString())
          .whereType<String>()
          .toList(),
      oaUrl: oaUrl,
      relatedWorkIds: List<String>.from(json['related_works'] ?? []),
      referencedWorkIds: List<String>.from(json['referenced_works'] ?? []),
    );
  }

  factory Publication.fromJsonBrief(Map<String, dynamic> json) {
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    final bestOa = json['best_oa_location'] as Map<String, dynamic>?;
    final openAccess = json['open_access'] as Map<String, dynamic>?;
    final oaUrl = bestOa?['pdf_url'] as String?
        ?? primaryLocation?['pdf_url'] as String?
        ?? openAccess?['oa_url'] as String?;
    final authors = (json['authorships'] as List? ?? [])
          .map((item) => item['author']?['display_name']?.toString())
          .whereType<String>()
          .toList();
    return Publication(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['display_name'] as String? ?? 'No title',
      authors: authors,
      publicationYear: json['publication_year'] as int?,
      journalName: json['primary_location']?['source']?['display_name'] as String?,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      doi: json['doi'] as String?,
      abstractText: null,
      oaUrl: oaUrl,
      relatedWorkIds: List<String>.from(json['related_works'] ?? []),
      referencedWorkIds: List<String>.from(json['referenced_works'] ?? []),
    );
  }

  String get displayYear => publicationYear?.toString() ?? 'Unknown year';
  String get displayJournal => journalName ?? 'Unknown journal';
  String get displayAuthors =>
      authors.isEmpty ? 'Unknown authors' : authors.join(', ');
}
