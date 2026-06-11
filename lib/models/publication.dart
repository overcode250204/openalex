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

  Publication({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.citedByCount,
    required this.journalName,
    required this.doi,
    required this.abstractText,
    required this.authors,
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
    );
  }

  String get displayYear {
    return publicationYear?.toString() ?? 'Unknown year';
  }

  String get displayJournal {
    return journalName ?? 'Unknown journal';
  }

  String get displayAuthors {
    if (authors.isEmpty) {
      return 'Unknown authors';
    }

    return authors.join(', ');
  }
}
