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
  final List<String> concepts;
  final List<String> institutions;
  final List<String> countries;
  final Map<int, int> citationsByYear;

  Publication({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.citedByCount,
    required this.journalName,
    required this.doi,
    required this.abstractText,
    required this.authors,
    this.concepts = const [],
    this.institutions = const [],
    this.countries = const [],
    this.citationsByYear = const {},
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
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
      concepts: (json['concepts'] as List? ?? [])
          .where((c) => (c['score'] as num? ?? 0) > 0.3)
          .map((c) => c['display_name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      institutions: (json['authorships'] as List? ?? [])
          .expand((a) => (a['institutions'] as List? ?? []))
          .map((i) => i['display_name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      countries: (json['authorships'] as List? ?? [])
          .expand<String>((a) => (a['countries'] as List? ?? []).cast<String>())
          .where((s) => s.isNotEmpty)
          .toList(),
      citationsByYear: Map.fromEntries(
        (json['counts_by_year'] as List? ?? []).map(
          (e) => MapEntry(
            e['year'] as int,
            e['cited_by_count'] as int? ?? 0,
          ),
        ),
      ),
    );
  }

  String get displayYear => publicationYear?.toString() ?? 'Unknown year';
  String get displayJournal => journalName ?? 'Unknown journal';
  String get displayAuthors =>
      authors.isEmpty ? 'Unknown authors' : authors.join(', ');
}
