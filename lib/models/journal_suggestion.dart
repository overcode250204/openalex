import 'package:flutter/foundation.dart';

@immutable
class JournalSuggestion {
  final String id;
  final String displayName;
  final int worksCount;
  final String? issnL;
  final String? publisher;

  const JournalSuggestion({
    required this.id,
    required this.displayName,
    required this.worksCount,
    this.issnL,
    this.publisher,
  });

  factory JournalSuggestion.fromJson(Map<String, dynamic> json) {
    return JournalSuggestion(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Unknown journal',
      worksCount: json['works_count'] as int? ?? 0,
      issnL: json['issn_l']?.toString(),
      publisher: json['host_organization_name']?.toString(),
    );
  }

  /// Short OpenAlex ID without the base URL prefix, e.g. "S4210169082"
  String get shortId => id.replaceAll('https://openalex.org/', '');
}
