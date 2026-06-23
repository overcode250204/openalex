class ZoteroItem {
  final String key;
  final String title;
  final String itemType;
  final String? date;
  final String? doi;
  final String? journal;
  final List<String> authors;

  ZoteroItem({
    required this.key,
    required this.title,
    required this.itemType,
    this.date,
    this.doi,
    this.journal,
    required this.authors,
  });

  factory ZoteroItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return ZoteroItem(
      key: json['key']?.toString() ?? '',
      title: data['title']?.toString() ?? 'No title',
      itemType: data['itemType']?.toString() ?? '',
      date: data['date']?.toString(),
      doi: data['DOI']?.toString(),
      journal: data['publicationTitle']?.toString(),
      authors: (data['creators'] as List? ?? [])
          .map((item) {
            final firstName = item['firstName']?.toString() ?? '';
            final lastName = item['lastName']?.toString() ?? '';
            return '$firstName $lastName'.trim();
          })
          .where((name) => name.isNotEmpty)
          .toList(),
    );
  }
}
