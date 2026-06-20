class JournalSource {
  final String id;
  final String sourceId;
  final String displayName;
  final String type;
  final String? issnL;
  final List<String> issn;
  final int worksCount;
  final int citedByCount;
  final int? hIndex;
  final String? hostOrganizationName;

  const JournalSource({
    required this.id,
    required this.sourceId,
    required this.displayName,
    required this.type,
    required this.issnL,
    required this.issn,
    required this.worksCount,
    required this.citedByCount,
    required this.hIndex,
    required this.hostOrganizationName,
  });

  factory JournalSource.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final summaryStats = json['summary_stats'] as Map<String, dynamic>?;

    return JournalSource(
      id: id,
      sourceId: id.split('/').last,
      displayName: json['display_name']?.toString() ?? 'Unknown journal',
      type: json['type']?.toString() ?? '',
      issnL: json['issn_l']?.toString(),
      issn: (json['issn'] as List? ?? [])
          .map((item) => item?.toString())
          .whereType<String>()
          .toList(),
      worksCount: json['works_count'] as int? ?? 0,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      hIndex: summaryStats?['h_index'] as int?,
      hostOrganizationName: json['host_organization_name']?.toString(),
    );
  }

  String get displayIssnL => issnL?.trim().isNotEmpty == true ? issnL! : 'N/A';

  String get displayPublisher {
    return hostOrganizationName?.trim().isNotEmpty == true
        ? hostOrganizationName!
        : 'Unknown publisher';
  }
}
