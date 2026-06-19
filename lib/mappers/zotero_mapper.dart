import 'package:openalex/models/publication.dart';

class ZoteroMapper {
  static Map<String, dynamic> fromPublication(Publication p) {
    return {
      'itemType': 'journalArticle',
      'title': p.title,
      'abstractNote': p.abstractText,
      'publicationTitle': p.journalName,
      'date': p.publicationYear?.toString(),
      'DOI': p.doi,
      'creators': p.authors.map((name) {
        final parts = name.trim().split(RegExp(r'\s+'));

        return {
          'creatorType': 'author',
          'firstName': parts.length > 1
              ? parts.sublist(0, parts.length - 1).join(' ')
              : '',
          'lastName': parts.isNotEmpty ? parts.last : name,
        };
      }).toList(),
      'tags': [
        {'tag': 'OpenAlex'},
        {'tag': 'RIPQMS'},
      ],
    }..removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      if (value is List && value.isEmpty) return true;
      return false;
    });
  }
}
