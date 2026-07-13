import '../publication/publication.dart';

class PublicationAiContext {
  static const int abstractCharacterLimit = 8000;

  final String title;
  final String authors;
  final String journal;
  final String year;
  final String citationCount;
  final String doi;
  final String openAccessUrl;
  final String abstractText;

  const PublicationAiContext({
    required this.title,
    required this.authors,
    required this.journal,
    required this.year,
    required this.citationCount,
    required this.doi,
    required this.openAccessUrl,
    required this.abstractText,
  });

  factory PublicationAiContext.fromPublication(Publication publication) {
    return PublicationAiContext(
      title: _clean(publication.title, fallback: 'Unknown title'),
      authors: publication.authors.isEmpty
          ? 'Unknown authors'
          : publication.authors
                .map(_clean)
                .where((name) => name.isNotEmpty)
                .join(', '),
      journal: _clean(publication.journalName, fallback: 'Unknown journal'),
      year: publication.publicationYear?.toString() ?? 'Unknown year',
      citationCount: publication.citedByCount.toString(),
      doi: _clean(publication.doi, fallback: 'No DOI available'),
      openAccessUrl: _clean(
        publication.oaUrl,
        fallback: 'No open-access PDF URL available',
      ),
      abstractText: _limit(
        _clean(
          publication.abstractText,
          fallback: 'No abstract available for this publication.',
        ),
        abstractCharacterLimit,
      ),
    );
  }

  String toPromptContext() {
    return '''
Publication metadata and abstract:
Title: $title
Authors: $authors
Journal: $journal
Publication year: $year
Citations: $citationCount
DOI: $doi
Open access URL: $openAccessUrl
Abstract: $abstractText
''';
  }

  static String _clean(String? value, {String fallback = ''}) {
    final normalized = value?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  static String _limit(String value, int maxCharacters) {
    if (value.length <= maxCharacters) return value;
    return '${value.substring(0, maxCharacters).trim()}...';
  }
}
