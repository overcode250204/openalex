class JournalSource {
  final String id;
  final String displayName;
  final String? publisher;
  final String? issnL;
  final String? homepageUrl;
  final String? countryCode;
  final int worksCount;
  final int citedByCount;

  const JournalSource({
    required this.id,
    required this.displayName,
    this.publisher,
    this.issnL,
    this.homepageUrl,
    this.countryCode,
    required this.worksCount,
    required this.citedByCount,
  });

  double get averageCitations =>
      worksCount == 0 ? 0.0 : citedByCount / worksCount;

  factory JournalSource.fromJson(Map<String, dynamic> json) {
    return JournalSource(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      publisher: json['host_organization_name']?.toString(),
      issnL: json['issn_l']?.toString(),
      homepageUrl: json['homepage_url']?.toString(),
      countryCode: json['country_code']?.toString(),
      worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
      citedByCount: (json['cited_by_count'] as num?)?.toInt() ?? 0,
    );
  }
}
