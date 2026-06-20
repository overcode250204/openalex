class OpenAlexKeyword {
  final String id;
  final String displayName;
  final int worksCount;
  final int citedByCount;

  const OpenAlexKeyword({
    required this.id,
    required this.displayName,
    required this.worksCount,
    required this.citedByCount,
  });

  factory OpenAlexKeyword.fromJson(Map<String, dynamic> json) {
    return OpenAlexKeyword(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Unknown keyword',
      worksCount: json['works_count'] is int ? json['works_count'] as int : 0,
      citedByCount: json['cited_by_count'] is int ? json['cited_by_count'] as int : 0,
    );
  }
}
